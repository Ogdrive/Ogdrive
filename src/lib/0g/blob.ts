import { ZgFile, MerkleTree } from '@0glabs/0g-ts-sdk';

/**
 * Creates a ZgFile object from a file
 * @param file The file to create a ZgFile from
 * @returns The ZgFile object and any error
 */
export async function createZgFile(file: File): Promise<[ZgFile | null, Error | null]> {
  try {
    // Create a temporary file with the data
    const tempFile = new File([await file.arrayBuffer()], file.name);
    const zgFile = await ZgFile.fromFilePath(file.name);
    return [zgFile, null];
  } catch (error) {
    return [null, error instanceof Error ? error : new Error(String(error))];
  }
}

/**
 * Generates a Merkle tree from a ZgFile
 * @param zgFile The ZgFile to generate a Merkle tree from
 * @returns A promise that resolves to the Merkle tree and any error
 */
export async function generateMerkleTree(zgFile: ZgFile): Promise<[MerkleTree | null, Error | null]> {
  try {
    const [tree, treeErr] = await zgFile.merkleTree();
    if (treeErr !== null || !tree) {
      return [null, treeErr || new Error('Unknown error generating Merkle tree')];
    }
    return [tree, null];
  } catch (error) {
    return [null, error instanceof Error ? error : new Error(String(error))];
  }
}

/**
 * Gets the root hash from a Merkle tree
 * @param tree The Merkle tree
 * @returns The root hash and any error
 */
export function getRootHash(tree: MerkleTree): [string | null, Error | null] {
  try {
    const hash = tree.rootHash();
    if (!hash) {
      return [null, new Error('Failed to get root hash')];
    }
    return [hash, null];
  } catch (error) {
    return [null, error instanceof Error ? error : new Error(String(error))];
  }
}

/**
 * Creates a submission for upload from a ZgFile
 * @param zgFile The ZgFile to create a submission from
 * @returns A promise that resolves to the submission and any error
 */
export async function createSubmission(zgFile: ZgFile): Promise<[any | null, Error | null]> {
  try {
    console.log('[createSubmission] Starting submission creation...');
    console.log('[createSubmission] ZgFile size:', zgFile.size);
    console.log('[createSubmission] ZgFile type:', typeof zgFile);
    
    // Generate a unique tag using timestamp and random value
    // Ensure it's a valid hex string with even length
    const timestamp = Date.now();
    const randomValue = Math.floor(Math.random() * 1000000);
    const combinedValue = timestamp + randomValue;
    const hexString = combinedValue.toString(16);
    // Ensure even length by padding with leading zero if needed
    const paddedHex = hexString.length % 2 === 0 ? hexString : '0' + hexString;
    const uniqueTag = '0x' + paddedHex;
    
    console.log('[createSubmission] Generated unique tag:', uniqueTag);
    console.log('[createSubmission] Tag validation:', {
      original: combinedValue,
      hexString,
      paddedHex,
      finalTag: uniqueTag,
      isValidHex: /^0x[0-9a-fA-F]+$/.test(uniqueTag),
      isEvenLength: (uniqueTag.length - 2) % 2 === 0
    });
    
    const [submission, submissionErr] = await zgFile.createSubmission(uniqueTag);
    console.log('[createSubmission] createSubmission result:', { submission, submissionErr });
    
    if (submissionErr !== null || submission === null) {
      console.error('[createSubmission] Submission creation failed:', submissionErr);
      return [null, submissionErr || new Error('Unknown error creating submission')];
    }
    
    console.log('[createSubmission] Submission created successfully');
    console.log('[createSubmission] Submission type:', typeof submission);
    console.log('[createSubmission] Submission keys:', Object.keys(submission));
    console.log('[createSubmission] Submission details:', {
      length: submission.length,
      tags: submission.tags,
      nodes: submission.nodes ? submission.nodes.length : 'undefined'
    });
    
    return [submission, null];
  } catch (error) {
    console.error('[createSubmission] Error during submission creation:', error);
    return [null, error instanceof Error ? error : new Error(String(error))];
  }
} 