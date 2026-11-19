import { createAppKit } from '@reown/appkit/react';
import { EthersAdapter } from '@reown/appkit-adapter-ethers';
import { sepolia } from '@reown/appkit/networks';
import { PREDICT_EXCHANGE_ADDRESS, CHAIN_ID } from '../config';

const projectId = '72f4478a8aade181534dd47cc7786129';
const metadata = {
  name: 'PredictExchange',
  description: 'Prediction market dApp',
  url: window.location.origin,
  icons: ['https://avatars.githubusercontent.com/u/37784886']
};

// Настройка адаптера для ethers
const ethersAdapter = new EthersAdapter();

createAppKit({
  adapters: [ethersAdapter],
  networks: [sepolia],
  metadata,
  projectId,
  features: { analytics: true }
});

export default function WalletConnect({ onConnect, onDisconnect }) {
  return <appkit-button />;
}