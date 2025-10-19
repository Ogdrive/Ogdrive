# 0G Drive - Decentralized Storage Solution

A modern web application for decentralized file storage and management built on the 0G blockchain network. 0G Drive enables users to upload, download, and securely share files using blockchain-backed storage infrastructure.

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Running the Application](#running-the-application)
- [Usage](#usage)
- [API Documentation](#api-documentation)
- [Core Modules](#core-modules)
- [Development](#development)
- [Building & Deployment](#building--deployment)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

### File Management
- **Upload Files**: Upload files to 0G Storage with automatic transaction handling
- **Download Files**: Retrieve stored files using content-addressed root hashes
- **File Organization**: Create folders and organize files in a hierarchical structure
- **Metadata Tracking**: Store file metadata (name, size, type, upload date)

### Wallet Integration
- **Web3 Wallet Connection**: Connect using WalletConnect and injected wallets
- **Multi-Network Support**: Toggle between different 0G Network configurations
- **Transaction Management**: Monitor gas fees and transaction status
- **Wallet-Based Access Control**: Files are associated with wallet addresses

### File Sharing
- **Secure Sharing**: Share files with other wallet addresses
- **Access Control**: Track who files are shared with
- **Unshare Functionality**: Revoke sharing permissions

### User Experience
- **Drag & Drop Upload**: Intuitive file upload with drag-and-drop interface
- **File Preview**: View file information before download
- **Progress Tracking**: Real-time upload/download status updates
- **Error Handling**: Comprehensive error messages and recovery

### Data Persistence
- **IndexedDB Storage**: Client-side persistent storage for file metadata
- **Blockchain Verification**: File hashes stored on-chain for authenticity

## 🔧 Tech Stack

### Frontend
- **Framework**: [Next.js](https://nextjs.org/) 14.2.5 - React framework with SSR/SSG
- **UI Library**: [React](https://react.dev/) 18.3.1
- **Styling**: [Tailwind CSS](https://tailwindcss.com/) 3.4.1
- **Language**: TypeScript
- **State Management**: React Context API + React Query
- **Blockchain Integration**: [Wagmi](https://wagmi.sh/) 2.14.8, [Viem](https://viem.sh/) 2.22.10

### Backend
- **Runtime**: Next.js API Routes
- **Storage**: Filesystem (JSON file storage for metadata)
- **Blockchain RPC**: 0G Network testnet endpoints

### Storage
- **0G Storage Network**: Decentralized storage via 0G Labs SDK
- **Client Cache**: IndexedDB for local metadata caching
- **Transaction Layer**: Ethereum-compatible smart contracts

### Web3 & Blockchain
- **SDK**: [@0glabs/0g-ts-sdk](https://www.npmjs.com/package/@0glabs/0g-ts-sdk) 0.3.0
- **Wallet Connection**: [@web3modal/wagmi](https://www.npmjs.com/package/@web3modal/wagmi) 5.1.11
- **Ethereum Utilities**: ethers.js (via wagmi)

### Development Tools
- **Build Tool**: Webpack (custom SDK build)
- **Linting**: ESLint
- **Package Manager**: npm

## 🏗️ Architecture

### Layered Architecture

```
┌─────────────────────────────────────┐
│     UI Components / Pages           │
│  (Upload, Download, Share, etc.)    │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│     Hooks & Context                 │
│  (useUpload, useDownload,           │
│   useShare, FileListContext)        │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│     API Routes & Utilities          │
│  (/api/files, /api/backup, etc.)   │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│     0G Protocol Layer               │
│  (uploader.ts, downloader.ts,      │
│   blob.ts, network.ts)             │
└────────────────┬────────────────────┘
                 │
┌────────────────▼────────────────────┐
│     Blockchain & Storage            │
│  (0G Storage Network, Contracts)   │
└─────────────────────────────────────┘
```

### Data Flow

**Upload Flow:**
1. User selects file via UI
2. File is converted to Blob
3. Root hash is calculated
4. Transaction submitted to Flow contract
5. File uploaded to 0G Storage
6. Metadata stored in IndexedDB + backend

**Download Flow:**
1. User requests file download
2. Root hash retrieved from metadata
3. File downloaded from 0G Storage RPC
4. File decrypted/decoded
5. Downloaded to user's device

## 📁 Project Structure

```
0gdrive-main/
├── src/
│   ├── app/
│   │   ├── api/                    # Next.js API routes
│   │   │   ├── files/              # File metadata management
│   │   │   ├── backup/             # Backup functionality
│   │   │   ├── proxy/              # Network proxy
│   │   │   └── [id]/               # Dynamic file routes
│   │   ├── share/
│   │   │   └── [rootHash]/         # Public file sharing pages
│   │   ├── layout.tsx              # Root layout with metadata
│   │   ├── page.tsx                # Home page wrapper
│   │   ├── client-page.tsx         # Main client-side page
│   │   ├── globals.css             # Global styles
│   │   └── providers.tsx           # App providers (Wagmi, Query, etc.)
│   │
│   ├── components/
│   │   ├── ClientLayout.tsx        # Main layout wrapper
│   │   ├── ConnectButton.tsx       # Wallet connection UI
│   │   ├── NetworkToggle.tsx       # Network selection
│   │   ├── common/                 # Shared components
│   │   │   ├── FileDropzone.tsx   # Drag-and-drop upload
│   │   │   ├── FileList.tsx        # File listing
│   │   │   ├── ShareModal.tsx      # File sharing UI
│   │   │   ├── FeeDisplay.tsx      # Gas fee display
│   │   │   └── TransactionStatus.tsx
│   │   ├── download/               # Download components
│   │   │   ├── DownloadCard.tsx
│   │   │   └── DownloadCardContainer.tsx
│   │   └── upload/                 # Upload components
│   │       ├── UploadCard.tsx
│   │       ├── UploadCardContainer.tsx
│   │       └── UploadModal.tsx
│   │
│   ├── context/
│   │   ├── FileListContext.tsx    # File management state
│   │   ├── WalletContext.tsx      # Wallet state
│   │   └── index.tsx              # Context providers
│   │
│   ├── hooks/
│   │   ├── useUpload.ts           # Upload logic hook
│   │   ├── useDownload.ts         # Download logic hook
│   │   ├── useShare.ts            # File sharing hook
│   │   ├── useWallet.ts           # Wallet connection hook
│   │   ├── useFileList.ts         # File list management
│   │   ├── useFees.ts             # Gas fee calculation
│   │   ├── useBackup.ts           # Backup functionality
│   │   └── useIndexedDB.ts        # IndexedDB operations
│   │
│   ├── lib/
│   │   ├── wagmi.ts               # Wagmi configuration
│   │   └── 0g/
│   │       ├── uploader.ts        # File upload to 0G Storage
│   │       ├── downloader.ts      # File download from 0G Storage
│   │       ├── blob.ts            # Blob manipulation utilities
│   │       ├── fees.ts            # Gas fee calculation
│   │       └── network.ts         # Network configuration
│   │
│   └── utils/
│       ├── crypto.ts              # Encryption/decryption utilities
│       ├── download.ts            # Download utility functions
│       ├── format.ts              # Formatting utilities
│       └── indexeddb.ts           # IndexedDB helper functions
│
├── public/
│   └── images/
│       └── wallets/               # Wallet icons
│
├── Dockerfile                     # Docker configuration
├── package.json                   # Dependencies
├── tsconfig.json                  # TypeScript config
├── tsconfig.sdk.json              # SDK-specific TypeScript config
├── webpack.sdk.config.js          # Webpack SDK build config
├── tailwind.config.ts             # Tailwind CSS config
└── README.md                       # This file
```

## 🚀 Getting Started

### Prerequisites

- **Node.js**: 18+ (LTS recommended)
- **npm**: 8+ or yarn
- **Web3 Wallet**: MetaMask or other WalletConnect-compatible wallet
- **0G Network**: Testnet access (funds for gas fees)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/0gdrive.git
   cd 0gdrive-main
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Build the SDK** (if needed)
   ```bash
   npm run build:sdk
   ```

### Configuration

1. **Copy environment template**
   ```bash
   cp env.example .env.local
   ```

2. **Configure environment variables** (`.env.local`)
   ```env
   # 0G Network Configuration
   NEXT_PUBLIC_L1_RPC=https://evmrpc-testnet.0g.ai
   NEXT_PUBLIC_EXPLORER_URL=https://chainscan-galileo.0g.ai/tx/

   # Smart Contract Addresses
   NEXT_PUBLIC_FLOW_ADDRESS=0xbD75117F80b4E22698D0Cd7612d92BDb8eaff628
   NEXT_PUBLIC_MINE_ADDRESS=0x3A0d1d67497Ad770d6f72e7f4B8F0BAbaa2A649C
   NEXT_PUBLIC_MARKET_ADDRESS=0x53191725d260221bBa307D8EeD6e2Be8DD265e19
   NEXT_PUBLIC_REWARD_ADDRESS=0xd3D4D91125D76112AE256327410Dd0414Ee08Cb4

   # Storage RPC
   NEXT_PUBLIC_STORAGE_RPC=https://indexer-storage-testnet-standard.0g.ai

   # WalletConnect
   NEXT_PUBLIC_PROJECT_ID=your_walletconnect_project_id_here

   # App URL
   NEXT_PUBLIC_APP_URL=https://localhost:3000
   ```

3. **Get WalletConnect Project ID**
   - Visit [WalletConnect Cloud](https://cloud.walletconnect.com)
   - Create a new project
   - Copy your Project ID to `NEXT_PUBLIC_PROJECT_ID`

### Running the Application

**Development Mode:**
```bash
npm run dev
```
Application runs on `http://localhost:3000`

**Production Build:**
```bash
npm run build
npm start
```

**Linting:**
```bash
npm run lint
```

## 💻 Usage

### Uploading Files

1. Connect your Web3 wallet
2. Click "Upload" button
3. Drag & drop files or select from file browser
4. Review file details and gas fees
5. Confirm transaction in wallet
6. File uploads to 0G Storage
7. Metadata stored in file list

### Downloading Files

1. Locate file in your file list
2. Click download icon
3. File is retrieved from 0G Storage
4. Browser downloads file automatically

### Sharing Files

1. Click share icon on file
2. Enter wallet address to share with
3. Confirm transaction
4. Recipient can access shared file

### Creating Folders

1. Click "New Folder" button
2. Enter folder name
3. Folder added to current directory

### Switching Networks

1. Click network toggle in top-right
2. Select desired network
3. Application context updates
4. All operations use new network

## 📡 API Documentation

### File Management API (`/api/files`)

**GET** - Retrieve file metadata
```typescript
Query: { walletAddress: string, parentId?: string | null }
Response: { files: Item[] }
```

**POST** - Create file/folder metadata
```typescript
Body: { type: 'file'|'folder', name: string, walletAddress: string, ... }
Response: { id: string, ... }
```

**PATCH** - Update or share file
```typescript
Body: { itemId: string, action: 'rename'|'move'|'share', ... }
Response: { success: boolean }
```

**DELETE** - Delete file/folder
```typescript
Query: { itemId: string, walletAddress: string }
Response: { success: boolean }
```

### Backup API (`/api/backup`)

**POST** - Backup file metadata
```typescript
Body: { walletAddress: string, data: Item[] }
Response: { backupId: string, hash: string }
```

### Proxy API (`/api/proxy`)

**GET** - Proxy storage requests
```typescript
Query: { url: string }
Response: File data (proxied response)
```

## 🔌 Core Modules

### useUpload Hook
Manages file upload lifecycle including:
- Blob creation and root hash calculation
- Transaction submission to Flow contract
- File upload to 0G Storage
- Metadata persistence
- Error handling and retry logic

```typescript
const { uploadFile, loading, error, uploadStatus } = useUpload();
await uploadFile(blob, submission, contract, storageFee, originalFile);
```

### useDownload Hook
Handles file download operations:
- Root hash validation
- 0G Storage RPC connection
- Blob retrieval and decoding
- Browser file download
- Progress tracking

```typescript
const { downloadFile, loading, error } = useDownload();
await downloadFile(rootHash, fileName);
```

### FileListContext
Provides file management state:
- File/folder list state
- Navigation and breadcrumbs
- CRUD operations
- Metadata formatting utilities

```typescript
const { items, loading, navigateToFolder, addFile } = useFileListContext();
```

### 0G Protocol Layer (`lib/0g/`)

**uploader.ts**: Core upload functionality
- Transaction submission to Flow contract
- File upload to 0G Storage network
- Error handling with retry logic

**downloader.ts**: File retrieval
- Download by root hash
- API-based retrieval with fallback
- Blob decoding and validation

**network.ts**: Network configuration
- Multiple network support
- RPC endpoint management
- Contract address configuration

**blob.ts**: Blob utilities
- Root hash calculation
- Chunk management
- Encoding/decoding

**fees.ts**: Gas fee calculation
- Fee estimation
- Provider and signer management

## 🛠️ Development

### Code Style
- TypeScript for type safety
- ESLint for code quality
- Follows Next.js best practices
- React Hooks for state management

### Key Design Patterns
- **Context API**: Global state management
- **Custom Hooks**: Reusable logic encapsulation
- **Component Composition**: Modular UI architecture
- **Error Boundaries**: Graceful error handling
- **SSR Prevention**: Client-side only components where needed

### Database Schema

**File/Folder Items (IndexedDB)**
```typescript
interface Item {
  id: string;
  type: 'file' | 'folder';
  name: string;
  parentId: string | null;
  walletAddress: string;
  uploadDate: string;
  fileExtension?: string;
  fileSize?: number;
  rootHash?: string;
  networkType?: string;
  sharedWith?: string[];
  sharedBy?: string;
}
```

## 🐳 Building & Deployment

### Docker Build

**Build Docker image:**
```bash
docker build -t 0gdrive:latest .
```

**Run Docker container:**
```bash
docker run -p 3000:3000 \
  -e NEXT_PUBLIC_L1_RPC=https://evmrpc-testnet.0g.ai \
  -e NEXT_PUBLIC_STORAGE_RPC=https://indexer-storage-testnet-standard.0g.ai \
  -e NEXT_PUBLIC_PROJECT_ID=your_project_id \
  0gdrive:latest
```

### Production Deployment

**Environment Setup:**
- Set all required environment variables
- Configure HTTPS/SSL certificates
- Set appropriate CORS headers
- Configure rate limiting if needed

**Performance Optimizations:**
- Enable Next.js compression
- Use CDN for static assets
- Implement caching strategies
- Monitor performance metrics

**Monitoring:**
- Set up error logging
- Monitor gas fees and transactions
- Track storage network health
- Monitor application performance

## 📚 Additional Resources

- [0G Network Documentation](https://0g.ai/docs)
- [Wagmi Documentation](https://wagmi.sh/)
- [Next.js Documentation](https://nextjs.org/docs)
- [Web3Modal Documentation](https://docs.walletconnect.com/appkit/overview)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for decentralized storage**

For questions or support, please open an issue in the repository or contact the development team.
