// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title OGFees
 * @dev Fee management and distribution contract for the 0G Drive platform
 */
contract OGFees is Initializable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");

    // Fee structure
    struct FeeConfig {
        uint256 baseStorageFee;     // Base fee per byte
        uint256 networkFee;         // Network processing fee
        uint256 sharingFee;        // Fee for sharing files
        uint256 minimumFee;        // Minimum fee for any operation
    }

    // State variables
    FeeConfig public feeConfig;
    address public treasury;
    mapping(address => bool) public discountedUsers;
    uint256 public discountPercentage;

    // Events
    event FeeConfigUpdated(
        uint256 baseStorageFee,
        uint256 networkFee,
        uint256 sharingFee,
        uint256 minimumFee
    );
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event DiscountedUserAdded(address indexed user);
    event DiscountedUserRemoved(address indexed user);
    event DiscountPercentageUpdated(uint256 oldPercentage, uint256 newPercentage);
    event FeeCollected(address indexed user, uint256 amount, string feeType);
    event FeeDistributed(address indexed recipient, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _treasury,
        uint256 _baseStorageFee,
        uint256 _networkFee,
        uint256 _sharingFee,
        uint256 _minimumFee,
        uint256 _discountPercentage
    ) initializer public {
        require(_treasury != address(0), "Invalid treasury address");
        require(_discountPercentage <= 100, "Invalid discount percentage");

        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(FEE_MANAGER_ROLE, msg.sender);

        treasury = _treasury;
        discountPercentage = _discountPercentage;

        feeConfig = FeeConfig({
            baseStorageFee: _baseStorageFee,
            networkFee: _networkFee,
            sharingFee: _sharingFee,
            minimumFee: _minimumFee
        });
    }

    /**
     * @dev Calculate storage fee
     * @param size File size in bytes
     * @return uint256 Total fee amount
     */
    function calculateStorageFee(uint256 size) public view returns (uint256) {
        uint256 fee = (size * feeConfig.baseStorageFee) + feeConfig.networkFee;
        if (fee < feeConfig.minimumFee) {
            return feeConfig.minimumFee;
        }
        return fee;
    }

    /**
     * @dev Calculate sharing fee
     * @return uint256 Sharing fee amount
     */
    function getSharingFee() public view returns (uint256) {
        return feeConfig.sharingFee;
    }

    /**
     * @dev Apply discount if applicable
     * @param user User address
     * @param amount Original fee amount
     * @return uint256 Discounted fee amount
     */
    function applyDiscount(address user, uint256 amount) public view returns (uint256) {
        if (!discountedUsers[user]) return amount;
        
        uint256 discount = (amount * discountPercentage) / 100;
        return amount - discount;
    }

    /**
     * @dev Collect fee from user
     * @param user User address
     * @param amount Fee amount
     * @param feeType Type of fee being collected
     */
    function collectFee(address user, uint256 amount, string memory feeType) external payable whenNotPaused onlyRole(FEE_MANAGER_ROLE) {
        require(msg.value >= amount, "Insufficient fee");
        
        emit FeeCollected(user, amount, feeType);
        
        // Send excess back to user
        if (msg.value > amount) {
            (bool success, ) = user.call{value: msg.value - amount}("");
            require(success, "Failed to return excess fee");
        }
    }

    /**
     * @dev Distribute collected fees to treasury
     */
    function distributeFees() external onlyRole(ADMIN_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to distribute");

        (bool success, ) = treasury.call{value: balance}("");
        require(success, "Failed to distribute fees");

        emit FeeDistributed(treasury, balance);
    }

    /**
     * @dev Update fee configuration
     */
    function updateFeeConfig(
        uint256 _baseStorageFee,
        uint256 _networkFee,
        uint256 _sharingFee,
        uint256 _minimumFee
    ) external onlyRole(ADMIN_ROLE) {
        feeConfig = FeeConfig({
            baseStorageFee: _baseStorageFee,
            networkFee: _networkFee,
            sharingFee: _sharingFee,
            minimumFee: _minimumFee
        });

        emit FeeConfigUpdated(
            _baseStorageFee,
            _networkFee,
            _sharingFee,
            _minimumFee
        );
    }

    /**
     * @dev Update treasury address
     */
    function updateTreasury(address _treasury) external onlyRole(ADMIN_ROLE) {
        require(_treasury != address(0), "Invalid treasury address");
        address oldTreasury = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(oldTreasury, _treasury);
    }

    /**
     * @dev Add discounted user
     */
    function addDiscountedUser(address user) external onlyRole(FEE_MANAGER_ROLE) {
        require(!discountedUsers[user], "Already a discounted user");
        discountedUsers[user] = true;
        emit DiscountedUserAdded(user);
    }

    /**
     * @dev Remove discounted user
     */
    function removeDiscountedUser(address user) external onlyRole(FEE_MANAGER_ROLE) {
        require(discountedUsers[user], "Not a discounted user");
        discountedUsers[user] = false;
        emit DiscountedUserRemoved(user);
    }

    /**
     * @dev Update discount percentage
     */
    function updateDiscountPercentage(uint256 _discountPercentage) external onlyRole(ADMIN_ROLE) {
        require(_discountPercentage <= 100, "Invalid discount percentage");
        uint256 oldPercentage = discountPercentage;
        discountPercentage = _discountPercentage;
        emit DiscountPercentageUpdated(oldPercentage, _discountPercentage);
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

    /**
     * @dev Required to receive ETH
     */
    receive() external payable {}
}