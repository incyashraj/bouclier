// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./interfaces/IBouclier.sol";
import "./PermissionVault.sol";

/// @dev ERC-6900 IModule interface (minimal subset for validation modules)
interface IERC6900Module {
    /// @notice Called during module installation on a modular account.
    function onInstall(bytes calldata data) external;

    /// @notice Called during module uninstallation.
    function onUninstall(bytes calldata data) external;

    /// @notice Returns the module type identifier.
    ///         Type 1 = Validation module
    function moduleId() external pure returns (string memory);
}

/// @dev ERC-6900 IValidationModule interface
interface IERC6900ValidationModule is IERC6900Module {
    /// @notice Validate a user operation. Returns 0 for success, 1 for failure.
    function validateUserOp(
        uint32 entityId,
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);

    /// @notice Validate a runtime call (non-UserOp execution).
    function validateRuntime(
        address account,
        uint32 entityId,
        address caller,
        uint256 value,
        bytes calldata data,
        bytes calldata authorization
    ) external;

    /// @notice Validate a signature (ERC-1271 style).
    function validateSignature(
        address account,
        uint32 entityId,
        address caller,
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4);
}

/// @title  ERC6900Adapter
/// @notice Adapts Bouclier's PermissionVault (ERC-7579 IValidator) to the ERC-6900
///         modular account standard. This is a thin wrapper — all enforcement logic
///         lives in PermissionVault.
///
///         ERC-6900 uses a different module interface than ERC-7579:
///         - `moduleId()` instead of `isModuleType(uint256)`
///         - `validateUserOp()` takes an extra `entityId` parameter
///         - Adds `validateRuntime()` and `validateSignature()` hooks
///
///         This adapter bridges the interface gap so Bouclier can be installed as a
///         validation module on both ERC-7579 and ERC-6900 modular accounts.
contract ERC6900Adapter is IERC6900ValidationModule {
    // ── Dependencies ─────────────────────────────────────────────
    PermissionVault public immutable permissionVault;

    // ── State ────────────────────────────────────────────────────
    // Tracks which accounts have installed this module
    mapping(address account => bool) public installed;

    // ── Constructor ──────────────────────────────────────────────
    constructor(address _permissionVault) {
        permissionVault = PermissionVault(payable(_permissionVault));
    }

    // ── IERC6900Module ───────────────────────────────────────────

    function moduleId() external pure override returns (string memory) {
        return "bouclier.permission-vault.v1";
    }

    function onInstall(bytes calldata /* data */) external override {
        installed[msg.sender] = true;
    }

    function onUninstall(bytes calldata /* data */) external override {
        installed[msg.sender] = false;
    }

    // ── IERC6900ValidationModule ─────────────────────────────────

    /// @notice Validate a UserOp by delegating to PermissionVault.
    ///         The entityId is ignored — Bouclier uses agentId (derived from sender).
    function validateUserOp(
        uint32  /* entityId */,
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256 validationData) {
        return permissionVault.validateUserOp(userOp, userOpHash);
    }

    /// @notice Runtime validation is not supported — Bouclier validates via UserOps only.
    ///         Reverts to prevent unvalidated runtime execution.
    function validateRuntime(
        address /* account */,
        uint32  /* entityId */,
        address /* caller */,
        uint256 /* value */,
        bytes calldata /* data */,
        bytes calldata /* authorization */
    ) external pure override {
        revert("ERC6900Adapter: runtime validation not supported - use UserOp flow");
    }

    /// @notice Signature validation is not directly supported.
    ///         Returns ERC-1271 failure magic value.
    function validateSignature(
        address /* account */,
        uint32  /* entityId */,
        address /* caller */,
        bytes32 /* hash */,
        bytes calldata /* signature */
    ) external pure override returns (bytes4) {
        return bytes4(0xffffffff); // ERC-1271 failure
    }
}
