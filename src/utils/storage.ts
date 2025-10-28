import { ZgFile } from '@0glabs/0g-ts-sdk';

/**
 * Get file extension from file name
 * @param fileName The file name
 * @returns The file extension (without dot)
 */
export function getFileExtension(fileName: string): string {
  const parts = fileName.split('.');
  return parts.length > 1 ? parts.pop()?.toLowerCase() || '' : '';
}

/**
 * Convert file size to bytes
 * @param size The size string (e.g., "1.5MB")
 * @returns The size in bytes
 */
export function sizeToBytes(size: string): number {
  const units: { [key: string]: number } = {
    'B': 1,
    'KB': 1024,
    'MB': 1024 * 1024,
    'GB': 1024 * 1024 * 1024,
    'TB': 1024 * 1024 * 1024 * 1024
  };

  const match = size.match(/^([\d.]+)\s*([KMGT]?B)$/i);
  if (!match) return 0;

  const value = parseFloat(match[1]);
  const unit = match[2].toUpperCase();

  return value * (units[unit] || 1);
}

/**
 * Calculate estimated storage cost based on file size
 * @param sizeInBytes The file size in bytes
 * @returns The estimated cost in wei
 */
export function calculateStorageCost(sizeInBytes: number): bigint {
  // Basic rate: 1 wei per byte
  const baseRate = BigInt(1);
  
  // Calculate base cost
  const baseCost = BigInt(sizeInBytes) * baseRate;
  
  // Add network overhead (10%)
  const overhead = baseCost / BigInt(10);
  
  return baseCost + overhead;
}

/**
 * Verify file integrity by comparing merkle roots
 * @param zgFile The ZgFile instance
 * @param expectedRoot The expected root hash
 * @returns A promise that resolves to [isValid, error]
 */
export async function verifyFileIntegrity(
  zgFile: ZgFile,
  expectedRoot: string
): Promise<[boolean, Error | null]> {
  try {
    const [tree, treeErr] = await zgFile.merkleTree();
    if (treeErr || !tree) {
      throw new Error(treeErr ? (treeErr as Error).message : 'Failed to generate merkle tree');
    }

    const [actualRoot, rootErr] = [tree.rootHash(), null];
    if (rootErr || !actualRoot) {
      throw new Error(rootErr?.message || 'Failed to get root hash');
    }

    return [actualRoot === expectedRoot, null];
  } catch (error) {
    return [false, error instanceof Error ? error : new Error(String(error))];
  }
}

/**
 * Generate a unique tag for file submission
 * Ensures the tag is a valid hex string with even length
 * @returns A unique hex tag with '0x' prefix
 */
export function generateUniqueTag(): string {
  const timestamp = Date.now();
  const randomValue = Math.floor(Math.random() * 1000000);
  const combinedValue = timestamp + randomValue;
  const hexString = combinedValue.toString(16);
  const paddedHex = hexString.length % 2 === 0 ? hexString : '0' + hexString;
  return '0x' + paddedHex;
}

/**
 * Validates file size against network limits
 * @param sizeInBytes The file size in bytes
 * @returns [isValid, error]
 */
export function validateFileSize(sizeInBytes: number): [boolean, Error | null] {
  const MAX_FILE_SIZE = 1024 * 1024 * 1024; // 1GB

  if (sizeInBytes <= 0) {
    return [false, new Error('File size must be greater than 0')];
  }

  if (sizeInBytes > MAX_FILE_SIZE) {
    return [false, new Error('File size exceeds maximum allowed size (1GB)')];
  }

  return [true, null];
}

/**
 * Validates root hash format
 * @param rootHash The root hash to validate
 * @returns [isValid, error]
 */
export function validateRootHash(rootHash: string): [boolean, Error | null] {
  if (!rootHash) {
    return [false, new Error('Root hash is required')];
  }

  // Root hash should be a valid hex string with '0x' prefix
  if (!/^0x[a-fA-F0-9]+$/.test(rootHash)) {
    return [false, new Error('Invalid root hash format')];
  }

  // Root hash should have a specific length (64 characters after '0x')
  if (rootHash.length !== 66) {
    return [false, new Error('Invalid root hash length')];
  }

  return [true, null];
}