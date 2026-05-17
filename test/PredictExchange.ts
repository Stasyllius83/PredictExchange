import { expect } from "chai";
import { network } from "hardhat";

describe("PredictExchange", function () {
  async function deployFixture() {
    const { ethers } = await network.connect();
    const [admin, oracle, user1, user2] = (await ethers.getSigners()) as any;

    // Мок-контракты
    const MockERC20Factory = await ethers.getContractFactory("MockERC20");
    const collateralToken = await MockERC20Factory.deploy("USDC", "USDC", 6);
    await collateralToken.waitForDeployment();

    const MockCTFFactory = await ethers.getContractFactory("MockConditionalTokens");
    const ctf = await MockCTFFactory.deploy(collateralToken.target);
    await ctf.waitForDeployment();

    const PredictExchangeFactory = await ethers.getContractFactory("PredictExchange");
    const exchange = await PredictExchangeFactory.deploy(collateralToken.target, ctf.target);
    await exchange.waitForDeployment();

    const mintAmount = ethers.parseUnits("100", 6);
    await collateralToken.mint(user1.address, mintAmount);
    await collateralToken.mint(user2.address, mintAmount);

    await collateralToken.connect(user1).approve(exchange.target, ethers.MaxUint256);
    await collateralToken.connect(user2).approve(exchange.target, ethers.MaxUint256);

    const MockAggregatorFactory = await ethers.getContractFactory("MockChainlinkAggregator");
    const aggregator = await MockAggregatorFactory.deploy(5000 * 100, 2);
    await aggregator.waitForDeployment();

    return { ethers, exchange, collateralToken, ctf, admin, oracle, user1, user2, aggregator };
  }

  // Вспомогательная функция подписи
  async function signOrder(
    order: any,
    signer: any,
    exchangeAddress: string,
    chainId: number,
    ethers: any
  ): Promise<string> {
    const domain = {
      name: "Predict Exchange",
      version: "1",
      chainId: chainId,
      verifyingContract: exchangeAddress,
    };
    const types = {
      Order: [
        { name: "salt", type: "uint256" },
        { name: "signer", type: "address" },
        { name: "tokenId", type: "uint256" },
        { name: "amount", type: "uint256" },
        { name: "expiration", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "side", type: "uint8" },
        { name: "bid", type: "uint8" },
      ],
    };
    return await signer.signTypedData(domain, types, order);
  }

  describe("Создание предсказания", function () {
    let exchange: any;
    let admin: any;
    let oracle: any;
    let user1: any;

    beforeEach(async function () {
      const fixture = await deployFixture();
      exchange = fixture.exchange;
      admin = fixture.admin;
      oracle = fixture.oracle;
      user1 = fixture.user1;
    });

    it("Должен создавать предсказание только админом", async function () {
      const question = "Will ETH > $5000?";
      const predictedPrice = 5000;
      const duration = 3600;

      await expect(exchange.connect(admin).createPrediction(question, oracle.address, predictedPrice, duration))
        .to.emit(exchange, "PredictionCreate");

      await expect(
        exchange.connect(user1).createPrediction(question, oracle.address, predictedPrice, duration)
      ).to.be.revertedWithCustomError(exchange, "NotAdmin");
    });

    it("Должен корректно сохранять параметры предсказания", async function () {
      const { ethers } = await network.connect();
      const question = "Will ETH > $5000?";
      const predictedPrice = 5000;
      const duration = 3600;
      const blockBefore = await ethers.provider.getBlock("latest");
      const startTimestamp = blockBefore!.timestamp;
      const expectedEndsAt = startTimestamp + duration;

      await exchange.connect(admin).createPrediction(question, oracle.address, predictedPrice, duration);
      const questionId = await exchange.getQuestionId(question);
      const pred = await exchange.getPredictionById(questionId);

      expect(pred.condition).to.equal(question);
      expect(pred.oracle).to.equal(oracle.address);
      expect(pred.predictedPrice).to.equal(predictedPrice);
      expect(pred.endsAt).to.be.closeTo(expectedEndsAt, 5);
    });
  });

  describe("Размещение ордеров", function () {
    let exchange: any;
    let ctf: any;
    let admin: any;
    let oracle: any;
    let user1: any;
    let user2: any;
    let questionId: string;
    let conditionId: string;
    let collateral: string;
    let chainId: number;
    let ethers: any;

    beforeEach(async function () {
      const eth = await network.connect();
      ethers = eth.ethers;
      const fixture = await deployFixture();
      exchange = fixture.exchange;
      ctf = fixture.ctf;
      admin = fixture.admin;
      oracle = fixture.oracle;
      user1 = fixture.user1;
      user2 = fixture.user2;
      collateral = await exchange.getCollateral();
      chainId = (await ethers.provider.getNetwork()).chainId;

      await exchange.connect(admin).createPrediction("Test question", oracle.address, 5000, 3600);
      questionId = await exchange.getQuestionId("Test question");
      const pred = await exchange.getPredictionById(questionId);
      conditionId = pred.conditionId;
    });

    async function getTokenId(bid: number): Promise<bigint> {
      return await ctf.getPositionId(collateral, conditionId, bid);
    }

    it("Должен создавать лимитный ордер на покупку", async function () {
      const amount = ethers.parseUnits("0.5", 6);
      const expiration = (await ethers.provider.getBlock("latest"))!.timestamp + 1000;
      const salt = ethers.randomBytes(32);
      const nonce = await exchange.nonces(user1.address);
      const tokenId = await getTokenId(1);

      const order = {
        salt: ethers.toBigInt(salt),
        signer: user1.address,
        tokenId: tokenId,
        amount: amount,
        expiration: expiration,
        nonce: nonce,
        side: 0,
        bid: 1,
      };
      const signature = await signOrder(order, user1, await exchange.getAddress(), chainId, ethers);

      await expect(exchange.connect(user1).fillOrder(questionId, salt, 0, 1, amount, expiration, signature))
        .to.emit(exchange, "OrderFilled");

      const pred = await exchange.getPredictionById(questionId);
      expect(pred.orders.length).to.equal(1);
    });

    it("Должен отклонять продажу без токенов CTF", async function () {
      const amount = ethers.parseUnits("0.5", 6);
      const expiration = (await ethers.provider.getBlock("latest"))!.timestamp + 1000;
      const salt = ethers.randomBytes(32);
      const nonce = await exchange.nonces(user2.address);
      const tokenId = await getTokenId(1);
      const order = {
        salt: ethers.toBigInt(salt),
        signer: user2.address,
        tokenId: tokenId,
        amount: amount,
        expiration: expiration,
        nonce: nonce,
        side: 1,
        bid: 1,
      };
      const signature = await signOrder(order, user2, await exchange.getAddress(), chainId, ethers);
      await expect(
        exchange.connect(user2).fillOrder(questionId, salt, 1, 1, amount, expiration, signature)
      ).to.be.revertedWith("Balance ctf zero");
    });

    it("Должен отклонять невалидную подпись", async function () {
      const amount = ethers.parseUnits("0.5", 6);
      const expiration = (await ethers.provider.getBlock("latest"))!.timestamp + 1000;
      const salt = ethers.randomBytes(32);
      const nonce = await exchange.nonces(user1.address);
      const tokenId = await getTokenId(1);
      const order = {
        salt: ethers.toBigInt(salt),
        signer: user1.address,
        tokenId: tokenId,
        amount: amount,
        expiration: expiration,
        nonce: nonce,
        side: 0,
        bid: 1,
      };
      const badSignature = await signOrder(order, user2, await exchange.getAddress(), chainId, ethers);
      await expect(
        exchange.connect(user1).fillOrder(questionId, salt, 0, 1, amount, expiration, badSignature)
      ).to.be.revertedWithCustomError(exchange, "InvalidSignature");
    });
  });

  describe("Разрешение предсказания и получение выигрыша", function () {
    let exchange: any;
    let collateralToken: any;
    let ctf: any;
    let admin: any;
    let user1: any;
    let aggregator: any;
    let questionId: string;
    let conditionId: string;
    let collateral: string;
    let chainId: number;
    let ethers: any;

    beforeEach(async function () {
      const eth = await network.connect();
      ethers = eth.ethers;
      const fixture = await deployFixture();
      exchange = fixture.exchange;
      collateralToken = fixture.collateralToken;
      ctf = fixture.ctf;
      admin = fixture.admin;
      user1 = fixture.user1;
      aggregator = fixture.aggregator;
      collateral = await exchange.getCollateral();
      chainId = (await ethers.provider.getNetwork()).chainId;

      await exchange.connect(admin).createPrediction("ETH price", aggregator.target, 5000, 10);
      questionId = await exchange.getQuestionId("ETH price");
      const pred = await exchange.getPredictionById(questionId);
      conditionId = pred.conditionId;
    });

    async function getTokenId(bid: number): Promise<bigint> {
      return await ctf.getPositionId(collateral, conditionId, bid);
    }

    it("Только админ может разрешить предсказание", async function () {
      await ethers.provider.send("evm_increaseTime", [20]);
      await ethers.provider.send("evm_mine");
      await expect(exchange.connect(user1).resolvePrediction(questionId)).to.be.revertedWithCustomError(
        exchange,
        "NotAdmin"
      );
      await expect(exchange.connect(admin).resolvePrediction(questionId)).to.emit(
        exchange,
        "PredictionResolved"
      );
    });

    it("Пользователь получает выигрыш при исходе YES", async function () {
      await aggregator.setPrice(6000 * 100);
      const amount = ethers.parseUnits("0.5", 6);
      const expiration = (await ethers.provider.getBlock("latest"))!.timestamp + 100;
      const tokenId = await getTokenId(1);
      const nonce = await exchange.nonces(user1.address);
      const salt = ethers.randomBytes(32);
      const order = {
        salt: ethers.toBigInt(salt),
        signer: user1.address,
        tokenId: tokenId,
        amount: amount,
        expiration: expiration,
        nonce: nonce,
        side: 0,
        bid: 1,
      };
      const signature = await signOrder(order, user1, await exchange.getAddress(), chainId, ethers);
      await exchange.connect(user1).fillOrder(questionId, salt, 0, 1, amount, expiration, signature);

      await ethers.provider.send("evm_increaseTime", [20]);
      await ethers.provider.send("evm_mine");
      await exchange.connect(admin).resolvePrediction(questionId);

      const outcome = await exchange.predictionOutcome(questionId);
      expect(outcome).to.equal(true);

      const winningAmount = await exchange.winningTokenAmount(questionId);
      const userBalanceBefore = await collateralToken.balanceOf(user1.address);
      await expect(exchange.connect(user1).claimWinnings(questionId))
        .to.emit(exchange, "WinningsClaimed")
        .withArgs(user1.address, questionId, winningAmount, true);
      const userBalanceAfter = await collateralToken.balanceOf(user1.address);
      expect(userBalanceAfter).to.be.gt(userBalanceBefore);

      const claimed = await exchange.hasClaimed(questionId, user1.address);
      expect(claimed).to.equal(true);
    });

    it("Нельзя получить выигрыш дважды", async function () {
      await aggregator.setPrice(6000 * 100);
      const amount = ethers.parseUnits("0.5", 6);
      const expiration = (await ethers.provider.getBlock("latest"))!.timestamp + 100;
      const tokenId = await getTokenId(1);
      const nonce = await exchange.nonces(user1.address);
      const salt = ethers.randomBytes(32);
      const order = {
        salt: ethers.toBigInt(salt),
        signer: user1.address,
        tokenId: tokenId,
        amount: amount,
        expiration: expiration,
        nonce: nonce,
        side: 0,
        bid: 1,
      };
      const signature = await signOrder(order, user1, await exchange.getAddress(), chainId, ethers);
      await exchange.connect(user1).fillOrder(questionId, salt, 0, 1, amount, expiration, signature);

      await ethers.provider.send("evm_increaseTime", [20]);
      await ethers.provider.send("evm_mine");
      await exchange.connect(admin).resolvePrediction(questionId);
      await exchange.connect(user1).claimWinnings(questionId);
      await expect(exchange.connect(user1).claimWinnings(questionId)).to.be.revertedWith("Already claimed");
    });
  });
});
