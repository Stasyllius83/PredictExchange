import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const collateralParam = "0x06FA1911EceFC68dd4a991Af17467268F8B80201";
const ctfParam = "0xAa538D09c63e372f6FeF7d7FfC7948cc0cb603c0";

export default buildModule("PredictExchangeModule", (m) => {
    const collateral = m.getParameter("collateral", collateralParam);
    const ctf = m.getParameter("ctf", ctfParam);
    const predictExchange = m.contract("PredictExchange", [
    collateral,
    ctf,
  ]);

  return { predictExchange };
});
