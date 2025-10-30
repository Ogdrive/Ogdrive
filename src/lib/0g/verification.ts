import { ZgFile } from '@0glabs/0g-ts-sdk';
import { ethers } from 'ethers';
import { getSigner, getProvider } from './fees';
import { getNetworkConfig } from './network';
import { NetworkType } from '@/app/providers';

interface VerificationResult {
  verified: boolean;
  rootHash: string;
  timestamp: number;
  submitter: string;
  error?: string;
}

/**
 * Verifies file existence and integrity on-chain
 * @param rootHash The root hash of the file to verify
 * @param networkType The network type to use for verification
 * @returns Promise<VerificationResult>
 */
export async function verifyFileOnChain(
  rootHash: string,
  networkType: NetworkType
): Promise<VerificationResult> {
  try {
    const network = getNetworkConfig(networkType);
    const provider = new ethers.JsonRpcProvider(network.l1Rpc);
    
    // Get the flow contract instance
    const flowAbi = ['function getFileInfo(bytes32 rootHash) view returns (address submitter, uint256 timestamp)'];
    const flowContract = new ethers.Contract(network.flowAddress, flowAbi, provider);
    
    // Convert root hash to bytes32 format
    const rootHashBytes = ethers.hexlify(rootHash);
    
    // Get file info from the contract
    const [submitter, timestamp] = await flowContract.getFileInfo(rootHashBytes);
    
    return {
      verified: true,
      rootHash,
      timestamp: Number(timestamp),
      submitter
    };
  } catch (error) {
    return {
      verified: false,
      rootHash,
      timestamp: 0,
      submitter: ethers.ZeroAddress,
      error: error instanceof Error ? error.message : String(error)
    };
  }
}

/**
 * Verifies the integrity of a file by comparing its computed root hash with the on-chain record
 * @param zgFile The ZgFile instance to verify
 * @param networkType The network type to use for verification
 * @returns Promise<VerificationResult>
 */
export async function verifyFileIntegrity(
  zgFile: ZgFile,
  networkType: NetworkType
): Promise<VerificationResult> {
  try {
    // Generate merkle tree and get root hash
    const [tree, treeErr] = await zgFile.merkleTree();
    if (treeErr || !tree) {
      throw new Error(treeErr ? treeErr.message : 'Failed to generate merkle tree');
    }
    
    const rootHash = tree.rootHash();
    if (!rootHash) {
      throw new Error('Failed to get root hash from merkle tree');
    }
    
    // Verify the root hash on-chain
    return await verifyFileOnChain(rootHash, networkType);
  } catch (error) {
    return {
      verified: false,
      rootHash: '',
      timestamp: 0,
      submitter: ethers.ZeroAddress,
      error: error instanceof Error ? error.message : String(error)
    };
  }
}

/**
 * Submits a file verification transaction on-chain
 * @param rootHash The root hash to verify
 * @param networkType The network type to use
 * @returns Promise<[string, Error | null]> Transaction hash and error if any
 */
export async function submitVerificationTransaction(
  rootHash: string,
  networkType: NetworkType
): Promise<[string, Error | null]> {
  try {
    const network = getNetworkConfig(networkType);
    const [provider, providerErr] = await getProvider();
    if (!provider) {
      throw providerErr || new Error('Failed to get provider');
    }
    
    const [signer, signerErr] = await getSigner(provider);
    
    if (!signer || signerErr) {
      throw signerErr || new Error('Failed to get signer');
    }
    
    // Get the flow contract instance with signer
    const flowAbi = ['function verifyFile(bytes32 rootHash) payable'];
    const flowContract = new ethers.Contract(network.flowAddress, flowAbi, signer);
    
    // Convert root hash to bytes32
    const rootHashBytes = ethers.hexlify(rootHash);
    
    // Submit verification transaction
    const tx = await flowContract.verifyFile(rootHashBytes);
    await tx.wait();
    
    return [tx.hash, null];
  } catch (error) {
    return ['', error instanceof Error ? error : new Error(String(error))];
  }
}