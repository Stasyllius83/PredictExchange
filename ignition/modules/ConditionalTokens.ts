import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("ConditionalTokensModule", (m) => {
  const conditionalTokens = m.contract("ConditionalTokens");

  return { conditionalTokens };
});
