import { NetworkType } from '@/app/providers';

export interface NetworkConfig {
  name: string;
  flowAddress: string;
  mineAddress: string;
  marketAddress: string;
  rewardAddress: string;
  storageRpc: string;
  explorerUrl: string;
  l1Rpc: string;
}

/**
 * Gets network configuration based on network type
 * @param networkType The network type ('standard' or 'turbo')
 * @returns The network configuration
 */
export function getNetworkConfig(networkType: NetworkType): NetworkConfig {
  const NETWORKS: Record<string, NetworkConfig> = {
    standard: {
      name: '0G Mainnet',
      flowAddress: process.env.NEXT_PUBLIC_FLOW_ADDRESS || '0xbd75117f80b4e22698d0cd7612d92bdb8eaff628',
      mineAddress: process.env.NEXT_PUBLIC_MINE_ADDRESS || '0x3a0d1d67497ad770d6f72e7f4b8f0babaa2a649c',
      marketAddress: process.env.NEXT_PUBLIC_MARKET_ADDRESS || '0x53191725d260221bba307d8eed6e2be8dd265e19',
      rewardAddress: process.env.NEXT_PUBLIC_REWARD_ADDRESS || '0xd3d4d91125d76112ae256327410dd0414ee08cb4',
      storageRpc: process.env.NEXT_PUBLIC_STORAGE_RPC || 'https://indexer-storage.0g.ai',
      explorerUrl: process.env.NEXT_PUBLIC_EXPLORER_URL || 'https://chainscan.0g.ai/tx/',
      l1Rpc: process.env.NEXT_PUBLIC_L1_RPC || 'https://evmrpc.0g.ai'
    },
    turbo: {
      name: '0G Mainnet (Turbo)',
      flowAddress: process.env.NEXT_PUBLIC_FLOW_ADDRESS || '0xbd75117f80b4e22698d0cd7612d92bdb8eaff628',
      mineAddress: process.env.NEXT_PUBLIC_MINE_ADDRESS || '0x3a0d1d67497ad770d6f72e7f4b8f0babaa2a649c',
      marketAddress: process.env.NEXT_PUBLIC_MARKET_ADDRESS || '0x53191725d260221bba307d8eed6e2be8dd265e19',
      rewardAddress: process.env.NEXT_PUBLIC_REWARD_ADDRESS || '0xd3d4d91125d76112ae256327410dd0414ee08cb4',
      storageRpc: process.env.NEXT_PUBLIC_STORAGE_RPC || 'https://indexer-storage-turbo.0g.ai',
      explorerUrl: process.env.NEXT_PUBLIC_EXPLORER_URL || 'https://chainscan.0g.ai/tx/',
      l1Rpc: process.env.NEXT_PUBLIC_L1_RPC || 'https://evmrpc.0g.ai'
    }
  };
  
  return NETWORKS[networkType];
}

/**
 * Gets explorer URL for a transaction hash
 * @param txHash The transaction hash
 * @param networkType The network type
 * @returns The explorer URL
 */
export function getExplorerUrl(txHash: string, networkType: NetworkType): string {
  const network = getNetworkConfig(networkType);
  return network.explorerUrl + txHash;
} 