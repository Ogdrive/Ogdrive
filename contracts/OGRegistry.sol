// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title OGRegistry
 * @dev Registry contract for managing user profiles and permissions
 */
contract OGRegistry is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    struct UserProfile {
        bool isRegistered;
        string username;
        uint256 storageLimit;
        uint256 usedStorage;
        uint256 registrationDate;
    }

    // State variables
    mapping(address => UserProfile) private users;
    mapping(string => address) private usernameToAddress;
    uint256 private defaultStorageLimit;

    // Events
    event UserRegistered(address indexed user, string username);
    event StorageLimitUpdated(address indexed user, uint256 newLimit);
    event UsedStorageUpdated(address indexed user, uint256 newUsed);
    event DefaultStorageLimitUpdated(uint256 newLimit);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _defaultStorageLimit) initializer public {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        defaultStorageLimit = _defaultStorageLimit;
    }

    /**
     * @dev Register a new user
     * @param username Unique username for the user
     */
    function register(string memory username) external whenNotPaused {
        require(!users[msg.sender].isRegistered, "User already registered");
        require(bytes(username).length > 0, "Username cannot be empty");
        require(usernameToAddress[username] == address(0), "Username already taken");

        users[msg.sender] = UserProfile({
            isRegistered: true,
            username: username,
            storageLimit: defaultStorageLimit,
            usedStorage: 0,
            registrationDate: block.timestamp
        });

        usernameToAddress[username] = msg.sender;
        emit UserRegistered(msg.sender, username);
    }

    /**
     * @dev Update user's storage usage
     * @param user User address
     * @param newUsedStorage New storage usage value
     */
    function updateUsedStorage(address user, uint256 newUsedStorage) external onlyRole(VERIFIER_ROLE) {
        require(users[user].isRegistered, "User not registered");
        require(newUsedStorage <= users[user].storageLimit, "Storage limit exceeded");

        users[user].usedStorage = newUsedStorage;
        emit UsedStorageUpdated(user, newUsedStorage);
    }

    /**
     * @dev Update user's storage limit
     * @param user User address
     * @param newLimit New storage limit
     */
    function updateStorageLimit(address user, uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        require(users[user].isRegistered, "User not registered");
        require(newLimit >= users[user].usedStorage, "New limit below used storage");

        users[user].storageLimit = newLimit;
        emit StorageLimitUpdated(user, newLimit);
    }

    /**
     * @dev Update default storage limit for new users
     * @param newLimit New default storage limit
     */
    function updateDefaultStorageLimit(uint256 newLimit) external onlyRole(ADMIN_ROLE) {
        defaultStorageLimit = newLimit;
        emit DefaultStorageLimitUpdated(newLimit);
    }

    /**
     * @dev Get user profile
     * @param user User address
     * @return UserProfile User's profile data
     */
    function getUserProfile(address user) external view returns (UserProfile memory) {
        require(users[user].isRegistered, "User not registered");
        return users[user];
    }

    /**
     * @dev Get address by username
     * @param username Username to look up
     * @return address User's address
     */
    function getAddressByUsername(string memory username) external view returns (address) {
        address userAddress = usernameToAddress[username];
        require(userAddress != address(0), "Username not registered");
        return userAddress;
    }

    /**
     * @dev Check if user can store more data
     * @param user User address
     * @param size Size of data to store
     * @return bool Whether user can store data
     */
    function canStoreData(address user, uint256 size) external view returns (bool) {
        if (!users[user].isRegistered) return false;
        return users[user].usedStorage + size <= users[user].storageLimit;
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