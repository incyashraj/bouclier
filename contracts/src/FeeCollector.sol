// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title  FeeCollector — Optional protocol fee collection for Bouclier
/// @notice Collects small fees per permission grant or audit anchor.
///         Fee parameters are controlled by a timelock + admin (multisig).
///         Fees are optional and disabled by default (set to 0).
///
/// Fee types:
///   - GRANT_FEE: Charged per permission grant (in native ETH)
///   - ANCHOR_FEE: Charged per IPFS CID anchor (in native ETH)
///   - REGISTRATION_FEE: Charged per agent registration (in native ETH)
///
/// Governance:
///   - FEE_ADMIN_ROLE can update fee amounts (subject to MAX caps)
///   - TREASURY_ROLE can withdraw collected fees
///   - DEFAULT_ADMIN_ROLE manages role assignments

contract FeeCollector is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    // ── Roles ─────────────────────────────────────────────────────

    bytes32 public constant FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    bytes32 public constant TREASURY_ROLE  = keccak256("TREASURY_ROLE");
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");

    // ── Fee Types ─────────────────────────────────────────────────

    enum FeeType { Grant, Anchor, Registration }

    // ── State ─────────────────────────────────────────────────────

    /// @dev Fee amounts in wei (native ETH). Default: 0 (disabled).
    mapping(FeeType => uint256) public fees;

    /// @dev Maximum allowed fee per type (safety cap to prevent admin abuse)
    uint256 public constant MAX_GRANT_FEE        = 0.01 ether;   // $25 at $2500/ETH
    uint256 public constant MAX_ANCHOR_FEE       = 0.005 ether;  // $12.50
    uint256 public constant MAX_REGISTRATION_FEE = 0.02 ether;   // $50

    /// @dev Total fees collected (for accounting)
    uint256 public totalCollected;

    /// @dev Treasury address for withdrawals
    address public treasury;

    // ── Events ────────────────────────────────────────────────────

    event FeeUpdated(FeeType indexed feeType, uint256 oldFee, uint256 newFee);
    event FeeCollected(FeeType indexed feeType, address indexed payer, uint256 amount);
    event FeesWithdrawn(address indexed to, uint256 amount);
    event TreasuryUpdated(address indexed oldTreasury, address indexed newTreasury);
    event ERC20Recovered(address indexed token, address indexed to, uint256 amount);

    // ── Errors ────────────────────────────────────────────────────

    error FeeExceedsMaximum(FeeType feeType, uint256 attempted, uint256 maximum);
    error InsufficientFee(uint256 required, uint256 provided);
    error ZeroAddress();
    error WithdrawFailed();

    // ── Constructor ───────────────────────────────────────────────

    constructor(address admin, address _treasury) {
        if (admin == address(0) || _treasury == address(0)) revert ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(FEE_ADMIN_ROLE, admin);
        _grantRole(TREASURY_ROLE, admin);

        treasury = _treasury;
    }

    // ── Fee Collection ────────────────────────────────────────────

    /// @notice Collect fee for a given type. Called by integrated contracts.
    /// @dev    Reverts if msg.value < required fee. Refunds excess.
    function collectFee(FeeType feeType, address payer) external payable onlyRole(COLLECTOR_ROLE) whenNotPaused {
        uint256 required = fees[feeType];
        if (required == 0) return; // fees disabled for this type

        if (msg.value < required) revert InsufficientFee(required, msg.value);

        totalCollected += required;

        // Refund excess
        uint256 excess = msg.value - required;
        if (excess > 0) {
            (bool ok,) = payer.call{value: excess}("");
            require(ok, "FeeCollector: refund failed");
        }

        emit FeeCollected(feeType, payer, required);
    }

    /// @notice Check the current fee for a given type.
    function getFee(FeeType feeType) external view returns (uint256) {
        return fees[feeType];
    }

    // ── Fee Administration ────────────────────────────────────────

    /// @notice Update fee amount for a given type.
    function setFee(FeeType feeType, uint256 amount) external onlyRole(FEE_ADMIN_ROLE) {
        uint256 maxFee = _getMaxFee(feeType);
        if (amount > maxFee) revert FeeExceedsMaximum(feeType, amount, maxFee);

        uint256 oldFee = fees[feeType];
        fees[feeType] = amount;
        emit FeeUpdated(feeType, oldFee, amount);
    }

    /// @notice Update treasury address.
    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_treasury == address(0)) revert ZeroAddress();
        address old = treasury;
        treasury = _treasury;
        emit TreasuryUpdated(old, _treasury);
    }

    // ── Withdrawals ───────────────────────────────────────────────

    /// @notice Withdraw collected fees to treasury.
    function withdraw() external onlyRole(TREASURY_ROLE) {
        uint256 balance = address(this).balance;
        if (balance == 0) return;

        (bool ok,) = treasury.call{value: balance}("");
        if (!ok) revert WithdrawFailed();

        emit FeesWithdrawn(treasury, balance);
    }

    /// @notice Recover accidentally sent ERC-20 tokens.
    function recoverERC20(address token, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC20(token).safeTransfer(treasury, amount);
        emit ERC20Recovered(token, treasury, amount);
    }

    // ── Pause ─────────────────────────────────────────────────────

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }

    // ── Internal ──────────────────────────────────────────────────

    function _getMaxFee(FeeType feeType) internal pure returns (uint256) {
        if (feeType == FeeType.Grant) return MAX_GRANT_FEE;
        if (feeType == FeeType.Anchor) return MAX_ANCHOR_FEE;
        return MAX_REGISTRATION_FEE;
    }

    /// @dev Accept ETH directly (for fee payments)
    receive() external payable {}
}
