import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

const Side = { BUY: 0, SELL: 1 };
const Bid = { NO: 0, YES: 1 };
const ONE = 1_000_000; // as in contract
const MAX_AMOUNT = 1; // Максимум 1 USDC
const MIN_AMOUNT = 0.000001; // Минимум 0.000001 USDC (1 wei)

const PredictionDetail = ({ question, predictExchange, conditionalTokens, usdc, account, signer, onClose, isAdmin }) => {
  const [prediction, setPrediction] = useState(null);
  const [yesPrice, setYesPrice] = useState(null);
  const [noPrice, setNoPrice] = useState(null);
  const [selectedBid, setSelectedBid] = useState(Bid.YES);
  const [amount, setAmount] = useState('');
  const [amountError, setAmountError] = useState('');
  const [expirationHours, setExpirationHours] = useState('');
  const [expirationMinutes, setExpirationMinutes] = useState('');
  const [loading, setLoading] = useState(false);
  const [questionId, setQuestionId] = useState(null);
  const [ctfBalance, setCtfBalance] = useState(null);
  const [selectedBidForSell, setSelectedBidForSell] = useState(Bid.YES);
  const [sellAmount, setSellAmount] = useState('');
  const [sellAmountError, setSellAmountError] = useState('');
  const [selling, setSelling] = useState(false);
  const [isResolved, setIsResolved] = useState(false);
  const [outcome, setOutcome] = useState(null);
  const [winningTokenAmount, setWinningTokenAmount] = useState(null);
  const [hasClaimed, setHasClaimed] = useState(false);
  const [userWinningBalance, setUserWinningBalance] = useState(0);
  const [resolving, setResolving] = useState(false);
  const [claiming, setClaiming] = useState(false);

  useEffect(() => {
    const fetchData = async () => {
      if (!predictExchange || !question) return;
      try {
        const qId = await predictExchange.getQuestionId(question);
        setQuestionId(qId);
        const pred = await predictExchange.getPredictionById(qId);
        setPrediction(pred);
        const yPrice = await predictExchange.getYesPrice(qId);
        const nPrice = await predictExchange.getNoPrice(qId);
        setYesPrice(Number(yPrice));
        setNoPrice(Number(nPrice));
        
        // Загружаем баланс CTF
        await fetchCtfBalance(qId);
        
        // Загружаем статус разрешения предсказания
        await fetchResolutionStatus(qId);
        
        // Загружаем информацию о выигрыше пользователя
        await fetchUserWinningInfo(qId);
      } catch (err) {
        console.error(err);
      }
    };
    fetchData();
  }, [predictExchange, question]);

  // Функция для получения статуса разрешения предсказания
  const fetchResolutionStatus = async (qId) => {
    if (!predictExchange || !qId) return;
    try {
      const resolved = await predictExchange.predictionResolved(qId);
      setIsResolved(resolved);
      
      if (resolved) {
        const outcomeResult = await predictExchange.predictionOutcome(qId);
        const winningAmount = await predictExchange.winningTokenAmount(qId);
        setOutcome(outcomeResult);
        setWinningTokenAmount(Number(winningAmount));
      }
    } catch (err) {
      console.error("Error fetching resolution status:", err);
    }
  };

  // Функция для получения информации о выигрыше пользователя
  const fetchUserWinningInfo = async (qId) => {
    if (!predictExchange || !account || !qId || !conditionalTokens) return;
    try {
      // Проверяем, получал ли пользователь выигрыш
      const claimed = await predictExchange.hasClaimed(qId, account);
      setHasClaimed(claimed);
      
      const conditionId = prediction?.conditionId || await predictExchange.getPredictionById(qId).then(p => p.conditionId);
      if (!conditionId) return;
      const collateral = await predictExchange.getCollateral();
      const winningBid = outcome ? Bid.YES : Bid.NO;
      const tokenId = await conditionalTokens.getPositionId(collateral, conditionId, winningBid);
      const balance = await conditionalTokens.balanceOf(account, tokenId);
      setUserWinningBalance(Number(balance));
      
    } catch (err) {
      console.error("Error fetching user winning info:", err);
    }
  };

  // Функция для получения баланса CTF
  const fetchCtfBalance = async (qId) => {
    if (!conditionalTokens || !account || !qId) return;
    try {
      const conditionId = prediction?.conditionId || await predictExchange.getPredictionById(qId).then(p => p.conditionId);
      if (!conditionId) return;
      
      const collateral = await predictExchange.getCollateral();
      const yesTokenId = await conditionalTokens.getPositionId(collateral, conditionId, Bid.YES);
      const noTokenId = await conditionalTokens.getPositionId(collateral, conditionId, Bid.NO);
      
      const yesBalance = await conditionalTokens.balanceOf(account, yesTokenId);
      const noBalance = await conditionalTokens.balanceOf(account, noTokenId);
      
      setCtfBalance({
        yes: Number(yesBalance),
        no: Number(noBalance),
        yesTokenId,
        noTokenId
      });
    } catch (err) {
      console.error("Error fetching CTF balance:", err);
    }
  };

  // Функция для разрешения предсказания (только для админа)
  const resolvePrediction = async () => {
    if (!predictExchange || !questionId || !isAdmin) {
      alert("Only admin can resolve predictions");
      return;
    }
    
    setResolving(true);
    try {
      const tx = await predictExchange.resolvePrediction(questionId);
      await tx.wait();
      alert("Prediction resolved successfully!");
      
      // Обновляем статус
      await fetchResolutionStatus(questionId);
      await fetchUserWinningInfo(questionId);
      await fetchCtfBalance(questionId);
    } catch (err) {
      console.error("Error resolving prediction:", err);
      alert(err.message || "Failed to resolve prediction");
    } finally {
      setResolving(false);
    }
  };

  // Функция для получения выигрыша
  const claimWinnings = async () => {
    if (!predictExchange || !questionId) {
      alert("Contract not connected");
      return;
    }
    
    if (!isResolved) {
      alert("Prediction not resolved yet");
      return;
    }
    
    if (hasClaimed) {
      alert("You have already claimed your winnings");
      return;
    }
    
    if (userWinningBalance === 0) {
      alert("You have no winnings to claim");
      return;
    }
    
    setClaiming(true);
    try {
      const tx = await predictExchange.claimWinnings(questionId);
      await tx.wait();
      alert("Winnings claimed successfully!");
      
      // Обновляем информацию
      await fetchUserWinningInfo(questionId);
      await fetchCtfBalance(questionId);
    } catch (err) {
      console.error("Error claiming winnings:", err);
      alert(err.message || "Failed to claim winnings");
    } finally {
      setClaiming(false);
    }
  };

  // Функция для валидации суммы покупки
  const validateAmount = (value) => {
    if (!value) {
      setAmountError('');
      return false;
    }
    
    const numValue = parseFloat(value);
    if (isNaN(numValue)) {
      setAmountError('Please enter a valid number');
      return false;
    }
    
    if (numValue <= 0) {
      setAmountError('Amount must be greater than 0');
      return false;
    }
    
    if (numValue < MIN_AMOUNT) {
      setAmountError(`Minimum amount is ${MIN_AMOUNT} USDC`);
      return false;
    }
    
    if (numValue > MAX_AMOUNT) {
      setAmountError(`Maximum amount is ${MAX_AMOUNT} USDC`);
      return false;
    }
    
    const decimalPlaces = value.toString().split('.')[1];
    if (decimalPlaces && decimalPlaces.length > 6) {
      setAmountError('Maximum 6 decimal places allowed');
      return false;
    }
    
    setAmountError('');
    return true;
  };
  // Функция для валидации суммы продажи
  const validateSellAmount = (value) => {
    if (!value) {
      setSellAmountError('');
      return false;
    }
    
    const numValue = parseFloat(value);
    if (isNaN(numValue)) {
      setSellAmountError('Please enter a valid number');
      return false;
    }
    
    if (numValue <= 0) {
      setSellAmountError('Amount must be greater than 0');
      return false;
    }
    
    const maxAmount = selectedBidForSell === Bid.YES ? ctfBalance?.yes : ctfBalance?.no;
    if (maxAmount !== undefined && numValue > maxAmount / ONE) {
      setSellAmountError(`You only have ${(maxAmount / ONE).toFixed(6)} tokens to sell`);
      return false;
    }
    
    const decimalPlaces = value.toString().split('.')[1];
    if (decimalPlaces && decimalPlaces.length > 6) {
      setSellAmountError('Maximum 6 decimal places allowed');
      return false;
    }
    
    setSellAmountError('');
    return true;
  };

  const handleAmountChange = (e) => {
    const newValue = e.target.value;
    setAmount(newValue);
    validateAmount(newValue);
  };

  const handleSellAmountChange = (e) => {
    const newValue = e.target.value;
    setSellAmount(newValue);
    validateSellAmount(newValue);
  };

  // Функция для преобразования часов и минут в секунды
  const convertToSeconds = (hours, minutes) => {
    const hoursNum = parseInt(hours) || 0;
    const minutesNum = parseInt(minutes) || 0;
    return (hoursNum * 3600) + (minutesNum * 60);
  };

  // Функция для форматирования времени для отображения
  const formatExpirationTime = (seconds) => {
    if (seconds === 0) return 'Never expires';
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const remainingSeconds = seconds % 60;
    const parts = [];
    if (hours > 0) parts.push(`${hours} hour${hours !== 1 ? 's' : ''}`);
    if (minutes > 0) parts.push(`${minutes} minute${minutes !== 1 ? 's' : ''}`);
    if (remainingSeconds > 0) parts.push(`${remainingSeconds} second${remainingSeconds !== 1 ? 's' : ''}`);
    
    return parts.join(' ') || '0 seconds';
  };

  const getTokenId = async (conditionId, bid) => {
    const collateral = await predictExchange.getCollateral();
    return await conditionalTokens.getPositionId(collateral, conditionId, bid);
  };

  const permitAndFillOrder = async () => {
    if (!signer || !amount || !questionId) return;
    
    if (!validateAmount(amount)) {
      alert(amountError || "Invalid amount");
      return;
    }
    
    const num = parseFloat(amount);
    const fillAmount = ethers.toBigInt(Math.round(num * ONE));
    
    if (fillAmount === ethers.toBigInt(0)) {
      alert("Amount must be greater than 0");
      return;
    }
    
    setLoading(true);
    try {   
      const side = Side.BUY;
      const bid = selectedBid;
      const salt = ethers.toBigInt(ethers.randomBytes(32));
      const nonce = await predictExchange.nonces(account) + 1n;
      
      const currentBlock = await signer.provider.getBlock("latest");
      const currentTimestamp = currentBlock.timestamp;
      const expirationSeconds = convertToSeconds(expirationHours, expirationMinutes);
      const expiration = currentTimestamp + expirationSeconds;
      
      if (currentTimestamp >= Number(prediction.endsAt)) {
        alert("This prediction has already ended!");
        setLoading(false);
        return;
      }
      
      const conditionId = prediction.conditionId;
      const tokenId = await getTokenId(conditionId, bid);
      
      const domain = {
        name: "Predict Exchange",
        version: "1",
        chainId: (await signer.provider.getNetwork()).chainId,
        verifyingContract: await predictExchange.getAddress()
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
          { name: "bid", type: "uint8" }
        ]
      };
      
      const orderValues = {
        salt: salt,
        signer: account,
        tokenId: tokenId,
        amount: fillAmount,
        expiration: expiration,
        nonce: nonce,
        side: side,
        bid: bid
      };
      
      const signature = await signer.signTypedData(domain, types, orderValues);
      
      if (side === Side.BUY) {
        const tokenContract = usdc.connect(signer);
        const owner = account;
        const spender = await predictExchange.getAddress();
        const value = fillAmount;
        const deadline = expiration; 
        const tokenNonce = await tokenContract.nonces(owner);
        
        const domainToken = {
          name: "USDC",
          version: "1",
          chainId: (await signer.provider.getNetwork()).chainId,
          verifyingContract: await tokenContract.getAddress()
        };
        
        const permitTypes = {
          Permit: [
            { name: "owner", type: "address" },
            { name: "spender", type: "address" },
            { name: "value", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" }
          ]
        };
        
        const permitData = {
          owner: owner,
          spender: spender,
          value: value,
          nonce: tokenNonce,
          deadline: deadline
        };
        
        const permitSig = await signer.signTypedData(domainToken, permitTypes, permitData);
        const { v, r, s } = ethers.Signature.from(permitSig);
        
        const permitTx = await tokenContract.permit(owner, spender, value, deadline, v, r, s);
        await permitTx.wait();
      }
      
      const tx = await predictExchange.fillOrder(
        questionId, salt, side, bid, fillAmount, expiration, signature
      );
      await tx.wait();
      
      // Обновляем баланс после покупки
      await fetchCtfBalance(questionId);
      await fetchUserWinningInfo(questionId);
      
      alert("Order filled successfully!");
    } catch (err) {
      console.error(err);
      alert(err.message || "Transaction failed");
    } finally {
      setLoading(false);
    }
  };

  const sellTokens = async () => {
    if (!signer || !sellAmount || !questionId) return;
    
    if (!validateSellAmount(sellAmount)) {
      alert(sellAmountError || "Invalid amount");
      return;
    }
    
    const num = parseFloat(sellAmount);
    const sellAmountWei = ethers.toBigInt(Math.round(num * ONE));
    
    if (sellAmountWei === ethers.toBigInt(0)) {
      alert("Amount must be greater than 0");
      return;
    }
    
    setSelling(true);
    try {
      const bid = selectedBidForSell;
      const side = Side.SELL;
      const salt = ethers.toBigInt(ethers.randomBytes(32));
      const nonce = await predictExchange.nonces(account) + 1n;
      
      const currentBlock = await signer.provider.getBlock("latest");
      const currentTimestamp = currentBlock.timestamp;
      const expirationSeconds = convertToSeconds(expirationHours, expirationMinutes);
      const expiration = currentTimestamp + expirationSeconds;
      
      if (currentTimestamp >= Number(prediction.endsAt)) {
        alert("This prediction has already ended!");
        setSelling(false);
        return;
      }
      
      const conditionId = prediction.conditionId;
      const tokenId = await getTokenId(conditionId, bid);
      
      // Сначала нужно approve для CTF токенов
      const ctfContract = conditionalTokens.connect(signer);
      const isApproved = await ctfContract.isApprovedForAll(account, await predictExchange.getAddress());
      
      if (!isApproved) {
        console.log("Approving CTF tokens...");
        const approveTx = await ctfContract.setApprovalForAll(await predictExchange.getAddress(), true);
        await approveTx.wait();
        console.log("CTF approval confirmed");
      }
      
      const domain = {
        name: "Predict Exchange",
        version: "1",
        chainId: (await signer.provider.getNetwork()).chainId,
        verifyingContract: await predictExchange.getAddress()
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
          { name: "bid", type: "uint8" }
        ]
      };
      
      const orderValues = {
        salt: salt,
        signer: account,
        tokenId: tokenId,
        amount: sellAmountWei,
        expiration: expiration,
        nonce: nonce,
        side: side,
        bid: bid
      };
      
      const signature = await signer.signTypedData(domain, types, orderValues);
      
      const tx = await predictExchange.fillOrder(
        questionId, salt, side, bid, sellAmountWei, expiration, signature
      );
      await tx.wait();
      
      // Обновляем баланс после продажи
      await fetchCtfBalance(questionId);
      await fetchUserWinningInfo(questionId);
      
      alert("Tokens sold successfully!");
      setSellAmount('');
    } catch (err) {
      console.error(err);
      alert(err.message || "Sale failed");
    } finally {
      setSelling(false);
    }
  };

  if (!prediction) return <div>Loading prediction...</div>;

  const formatPrice = (price) => {
    if (price === null || price === undefined) return '?';
    return (price / ONE).toFixed(6);
  };

  const isPredictionActive = () => {
    if (!prediction) return false;
    const now = Math.floor(Date.now() / 1000);
    return now < Number(prediction.endsAt) && !isResolved;
  };

  return (
    <div style={{ border: '1px solid #aaa', padding: '1rem', margin: '1rem 0', borderRadius: '8px' }}>
      <button onClick={onClose} style={{ float: 'right' }}>Close</button>
      <h3>Question: {question}</h3>
      <p>Condition ID: {prediction.conditionId}</p>
      <p>Oracle: {prediction.oracle}</p>
      <p>Ends at: {new Date(Number(prediction.endsAt) * 1000).toLocaleString()}</p>
      <p>Yes Price: {formatPrice(yesPrice)}</p>
      <p>No Price: {formatPrice(noPrice)}</p>
      
      {/* Статус разрешения предсказания */}
      <div style={{ 
        margin: '10px 0', 
        padding: '10px', 
        backgroundColor: isResolved ? (outcome ? '#c8e6c9' : '#ffcdd2') : '#fff3e0',
        borderRadius: '4px'
      }}>
        <strong>Prediction Status:</strong>
        {isResolved ? (
          <div>
            <p style={{ margin: '5px 0', color: outcome ? '#2e7d32' : '#c62828' }}>
              ✓ Resolved - Winner: {outcome ? 'YES' : 'NO'}
            </p>
            {winningTokenAmount !== null && (
              <p style={{ margin: '5px 0' }}>
                Total Winning Pool: {(winningTokenAmount / ONE).toFixed(6)} USDC
              </p>
            )}
          </div>
        ) : (
          <p style={{ margin: '5px 0', color: '#e65100' }}>
            ⏳ Pending resolution (ends at {new Date(Number(prediction.endsAt) * 1000).toLocaleString()})
          </p>
        )}
      </div>
      
      {/* Информация о выигрыше пользователя */}
      {isResolved && (
        <div style={{ 
          margin: '10px 0', 
          padding: '10px', 
          backgroundColor: '#e8f5e9',
          borderRadius: '4px'
        }}>
          <strong>Your Winnings:</strong>
          <p style={{ margin: '5px 0' }}>
            Amount: {(userWinningBalance > 0) ? (winningTokenAmount / ONE).toFixed(6) : '0.000000'} USDC
          </p>
          {!hasClaimed && userWinningBalance > 0 && (
            <button 
              onClick={claimWinnings} 
              disabled={claiming}
              style={{
                marginTop: '5px',
                padding: '8px 16px',
                backgroundColor: '#4CAF50',
                color: 'white',
                border: 'none',
                borderRadius: '4px',
                cursor: claiming ? 'not-allowed' : 'pointer'
              }}
            >
              {claiming ? "Claiming..." : "Claim Winnings"}
            </button>
          )}
          {hasClaimed && (
            <p style={{ margin: '5px 0', color: '#2e7d32' }}>
              ✓ Winnings already claimed
            </p>
          )}
        </div>
      )}
      
      {/* Информация если у пользователя нет выигрыша, но предсказание разрешено */}
      {isResolved && userWinningBalance === 0 && !hasClaimed && (
        <div style={{ 
          margin: '10px 0', 
          padding: '10px', 
          backgroundColor: '#fff3e0',
          borderRadius: '4px'
        }}>
          <p style={{ margin: '5px 0', color: '#e65100' }}>
            You have no winning tokens for this prediction.
          </p>
        </div>
      )}
      
      {/* Кнопка разрешения предсказания для админа */}
      {isAdmin && !isResolved && !isPredictionActive() && (
        <div style={{ margin: '10px 0' }}>
          <button 
            onClick={resolvePrediction} 
            disabled={resolving}
            style={{
              padding: '8px 16px',
              backgroundColor: '#ff9800',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              cursor: resolving ? 'not-allowed' : 'pointer'
            }}
          >
            {resolving ? "Resolving..." : "Resolve Prediction"}
          </button>
          <small style={{ display: 'block', color: '#666', marginTop: '5px' }}>
            Prediction period has ended. Click to determine the winner.
          </small>
        </div>
      )}
      
      {/* Отображение баланса CTF токенов */}
      {ctfBalance && (ctfBalance.yes > 0 || ctfBalance.no > 0) && (
        <div style={{ margin: '10px 0', padding: '10px', background: '#e3f2fd', borderRadius: '4px' }}>
          <strong>Your CTF Tokens:</strong>
          <p>YES tokens: {(ctfBalance.yes / ONE).toFixed(6)} USDC equivalent</p>
          <p>NO tokens: {(ctfBalance.no / ONE).toFixed(6)} USDC equivalent</p>
        </div>
      )}
      
      <hr />
      
      {/* Секция покупки - только если предсказание активно */}
      {isPredictionActive() && (
        <>
          <h4>Buy Tokens</h4>
          <div>
            <label>Bid: </label>
            <select value={selectedBid} onChange={e => setSelectedBid(Number(e.target.value))}>
              <option value={Bid.YES}>YES</option>
              <option value={Bid.NO}>NO</option>
            </select>
          </div>
          <div>
            <label>Amount (USDC): </label>
            <input
              type="number"
              step="0.000001"
              min={MIN_AMOUNT}
              max={MAX_AMOUNT}
              value={amount}
              onChange={handleAmountChange}
              placeholder={`e.g., 0.5 (max ${MAX_AMOUNT} USDC)`}
              style={{ borderColor: amountError ? 'red' : '#ccc' }}
            />
            {amountError && (
              <small style={{ display: 'block', color: 'red' }}>
                {amountError}
              </small>
            )}
          </div>
          
          <hr />
          <h4>Sell Tokens</h4>
          <div>
            <label>Token Type to Sell: </label>
            <select value={selectedBidForSell} onChange={e => setSelectedBidForSell(Number(e.target.value))}>
              <option value={Bid.YES}>YES Tokens</option>
              <option value={Bid.NO}>NO Tokens</option>
            </select>
          </div>
          <div>
            <label>Amount to Sell (tokens): </label>
            <input
              type="number"
              step="0.000001"
              min="0"
              value={sellAmount}
              onChange={handleSellAmountChange}
              placeholder={`Max: ${selectedBidForSell === Bid.YES && ctfBalance ? (ctfBalance.yes / ONE).toFixed(6) : selectedBidForSell === Bid.NO && ctfBalance ? (ctfBalance.no / ONE).toFixed(6) : '0'}`}
              style={{ borderColor: sellAmountError ? 'red' : '#ccc' }}
            />
            {sellAmountError && (
              <small style={{ display: 'block', color: 'red' }}>
                {sellAmountError}
              </small>
            )}
            <small style={{ display: 'block', color: '#666' }}>
              Available: {selectedBidForSell === Bid.YES && ctfBalance ? (ctfBalance.yes / ONE).toFixed(6) : selectedBidForSell === Bid.NO && ctfBalance ? (ctfBalance.no / ONE).toFixed(6) : '0'} tokens
            </small>
          </div>
          
          <div>
            <label>Expiration Time: </label>
            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
              <div>
                <input
                  type="number"
                  step="1"
                  min="0"
                  value={expirationHours}
                  onChange={e => setExpirationHours(e.target.value)}
                  placeholder="Hours"
                  style={{ width: '100px' }}
                />
                <small> hours</small>
              </div>
              <div>
                <input
                  type="number"
                  step="1"
                  min="0"
                  max="59"
                  value={expirationMinutes}
                  onChange={e => setExpirationMinutes(e.target.value)}
                  placeholder="Minutes"
                  style={{ width: '100px' }}
                />
                <small> minutes</small>
              </div>
            </div>
            <small style={{ display: 'block', color: '#666', marginTop: '5px' }}>
              {convertToSeconds(expirationHours, expirationMinutes) > 0 ? (
                <>Order will expire in: <strong>{formatExpirationTime(convertToSeconds(expirationHours, expirationMinutes))}</strong></>
              ) : (
                "Leave both fields empty or 0 for never expires"
              )}
            </small>
          </div>
          
          <div style={{ display: 'flex', gap: '10px', marginTop: '15px' }}>
            <button onClick={permitAndFillOrder} disabled={loading || !!amountError || !amount}>
              {loading ? "Processing..." : "Buy Tokens"}
            </button>
            <button 
              onClick={sellTokens} 
              disabled={selling || !!sellAmountError || !sellAmount || (selectedBidForSell === Bid.YES && (!ctfBalance || ctfBalance.yes === 0)) || (selectedBidForSell === Bid.NO && (!ctfBalance || ctfBalance.no === 0))}
              style={{ backgroundColor: '#ff9800' }}
            >
              {selling ? "Selling..." : "Sell Tokens"}
            </button>
          </div>
        </>
      )}
      
      {!isPredictionActive() && !isResolved && (
        <p style={{ textAlign: 'center', color: '#666', marginTop: '20px' }}>
          This prediction market has ended and is waiting for resolution.
        </p>
      )}
      
      {!isPredictionActive() && isResolved && (
        <p style={{ textAlign: 'center', color: '#666', marginTop: '20px' }}>
          This prediction has been resolved. {!hasClaimed && userWinningBalance > 0 ? "Claim your winnings above!" : "Trading is closed."}
        </p>
      )}
    </div>
  );
};

export default PredictionDetail;
