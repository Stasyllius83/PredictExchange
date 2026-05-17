import { useState, useEffect } from 'react';
import { createAppKit } from '@reown/appkit/react';
import { EthersAdapter } from '@reown/appkit-adapter-ethers';
import { sepolia } from '@reown/appkit/networks';
import { useAppKitAccount, useAppKitProvider } from '@reown/appkit/react';
import { ethers } from 'ethers';
import { BrowserProvider } from 'ethers';
import { PREDICT_EXCHANGE_ADDRESS, USDC_ADDRESS, CONDITIONAL_TOKENS_ADDRESS, CHAIN_ID } from './config';
import predictExchangeAbi from './abis/PredictExchange.json';
import conditionalTokensAbi from './abis/ConditionalTokens.json';
import usdcAbi from './abis/USDC.json';
import CreatePrediction from './components/CreatePrediction';
import PredictionList from './components/PredictionList';

const projectId = process.env.REACT_APP_REOWN_PROJECT_ID;

createAppKit({
  adapters: [new EthersAdapter()],
  networks: [sepolia],
  projectId,
  metadata: {
    name: 'PredictExchange',
    description: 'Prediction market dApp',
    url: window.location.origin,
    icons: ['https://avatars.githubusercontent.com/u/37784886']
  },
  features: { analytics: true }
});

function App() {
  const { isConnected, address } = useAppKitAccount();
  const { walletProvider } = useAppKitProvider('eip155');
  const [signer, setSigner] = useState(null);
  const [provider, setProvider] = useState(null);
  const [predictExchange, setPredictExchange] = useState(null);
  const [conditionalTokens, setConditionalTokens] = useState(null);
  const [usdc, setUsdc] = useState(null);
  const [isAdmin, setIsAdmin] = useState(false);

  useEffect(() => {
    const initEthers = async () => {
      if (isConnected && walletProvider) {
        const ethersProvider = new BrowserProvider(walletProvider);
        const ethersSigner = await ethersProvider.getSigner();
        const network = await ethersProvider.getNetwork();
        if (Number(network.chainId) !== CHAIN_ID) {
          alert(`Please switch to Sepolia (${CHAIN_ID})`);
          return;
        }
        setProvider(ethersProvider);
        setSigner(ethersSigner);
      } else {
        setSigner(null);
        setProvider(null);
      }
    };
    initEthers();
  }, [isConnected, walletProvider]);

  useEffect(() => {
    if (provider && signer) {
      const exchange = new ethers.Contract(PREDICT_EXCHANGE_ADDRESS, predictExchangeAbi.abi, signer);
      const ctf = new ethers.Contract(CONDITIONAL_TOKENS_ADDRESS, conditionalTokensAbi.abi, provider);
      const usdcContract = new ethers.Contract(USDC_ADDRESS, usdcAbi.abi, provider);
      setPredictExchange(exchange);
      setConditionalTokens(ctf);
      setUsdc(usdcContract);

      const checkAdmin = async () => {
        try {
          const admin = await exchange.isAdmin(address);
          setIsAdmin(admin);
        } catch (e) { console.error(e); }
      };
      checkAdmin();
    }
  }, [provider, signer, address]);

  return (
    <div className="App">
      <h1>PredictExchange</h1>
      <appkit-button />
      {isConnected && (
        <div>
          <p>Connected: {address}</p>
          {isAdmin && <CreatePrediction predictExchange={predictExchange} />}
          {predictExchange && conditionalTokens && usdc && (
            <PredictionList
              predictExchange={predictExchange}
              conditionalTokens={conditionalTokens}
              usdc={usdc}
              account={address}
              signer={signer}
              isAdmin={isAdmin}
            />
          )}
        </div>
      )}
    </div>
  );
}

export default App;
