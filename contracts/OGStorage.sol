// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 * @title OGStorage
 * @dev Main storage contract for the 0G Drive platform
 */
contract OGStorage is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // File metadata structure
    struct File {
        string rootHash;        // IPFS-like content hash
        address owner;         // File owner address
        uint256 timestamp;    // Upload timestamp
        bool exists;          // Existence flag
        mapping(address => bool) sharedWith;  // Sharing permissions
    }

    // State variables
    mapping(bytes32 => File) private files;
    mapping(address => bytes32[]) private userFiles;
    CountersUpgradeable.Counter private _fileCounter;

    // Events
    event FileUploaded(bytes32 indexed fileId, string rootHash, address indexed owner);
    event FileShared(bytes32 indexed fileId, address indexed owner, address indexed sharedWith);
    event FileUnshared(bytes32 indexed fileId, address indexed owner, address indexed unsharedWith);
    event FileDeleted(bytes32 indexed fileId, address indexed owner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Upload a new file
     * @param rootHash IPFS-like content hash of the file
     * @return fileId Unique identifier for the file
     */
    function uploadFile(string memory rootHash) external whenNotPaused returns (bytes32) {
        require(bytes(rootHash).length > 0, "Root hash cannot be empty");
        
        bytes32 fileId = keccak256(abi.encodePacked(rootHash, msg.sender, block.timestamp));
        require(!files[fileId].exists, "File already exists");

        File storage newFile = files[fileId];
        newFile.rootHash = rootHash;
        newFile.owner = msg.sender;
        newFile.timestamp = block.timestamp;
        newFile.exists = true;

        userFiles[msg.sender].push(fileId);
        _fileCounter.increment();

        emit FileUploaded(fileId, rootHash, msg.sender);
        return fileId;
    }

    /**
     * @dev Share a file with another address
     * @param fileId File identifier
     * @param user Address to share with
     */
    function shareFile(bytes32 fileId, address user) external whenNotPaused {
        require(files[fileId].exists, "File does not exist");
        require(files[fileId].owner == msg.sender, "Not file owner");
        require(user != address(0), "Invalid address");
        require(!files[fileId].sharedWith[user], "Already shared with user");

        files[fileId].sharedWith[user] = true;
        emit FileShared(fileId, msg.sender, user);
    }

    /**
     * @dev Revoke file access from an address
     * @param fileId File identifier
     * @param user Address to revoke access from
     */
    function unshareFile(bytes32 fileId, address user) external whenNotPaused {
        require(files[fileId].exists, "File does not exist");
        require(files[fileId].owner == msg.sender, "Not file owner");
        require(files[fileId].sharedWith[user], "Not shared with user");

        files[fileId].sharedWith[user] = false;
        emit FileUnshared(fileId, msg.sender, user);
    }

    /**
     * @dev Delete a file
     * @param fileId File identifier
     */
    function deleteFile(bytes32 fileId) external whenNotPaused {
        require(files[fileId].exists, "File does not exist");
        require(files[fileId].owner == msg.sender, "Not file owner");

        delete files[fileId];
        
        // Remove from user's file list
        bytes32[] storage userFileList = userFiles[msg.sender];
        for (uint i = 0; i < userFileList.length; i++) {
            if (userFileList[i] == fileId) {
                userFileList[i] = userFileList[userFileList.length - 1];
                userFileList.pop();
                break;
            }
        }

        _fileCounter.decrement();
        emit FileDeleted(fileId, msg.sender);
    }

    /**
     * @dev Check if user has access to a file
     * @param fileId File identifier
     * @param user Address to check
     * @return bool Access status
     */
    function hasAccess(bytes32 fileId, address user) public view returns (bool) {
        if (!files[fileId].exists) return false;
        return files[fileId].owner == user || files[fileId].sharedWith[user];
    }

    /**
     * @dev Get file metadata
     * @param fileId File identifier
     * @return rootHash File content hash
     * @return owner File owner address
     * @return timestamp Upload timestamp
     */
    function getFile(bytes32 fileId) external view returns (
        string memory rootHash,
        address owner,
        uint256 timestamp
    ) {
        require(files[fileId].exists, "File does not exist");
        require(hasAccess(fileId, msg.sender), "No access to file");

        File storage file = files[fileId];
        return (file.rootHash, file.owner, file.timestamp);
    }

    /**
     * @dev Get user's files
     * @param user Address to get files for
     * @return bytes32[] Array of file IDs
     */
    function getUserFiles(address user) external view returns (bytes32[] memory) {
        return userFiles[user];
    }

    /**
     * @dev Get total number of files
     * @return uint256 Total file count
     */
    function getTotalFiles() external view returns (uint256) {
        return _fileCounter.current();
    }

    /**
     * @dev Pause contract
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause contract
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Required by UUPSUpgradeable
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}