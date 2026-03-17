// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./interfaces/IBouclier.sol";
import "./PermissionVault.sol";
import "./AgentRegistry.sol";

/// @title  EIP7702Adapter
/// @notice Adapter that enables EIP-7702 EOA delegation to work with Bouclier.
///
///         EIP-7702 allows an EOA to temporarily delegate its code to a smart contract,
///         effectively turning it into a smart account for one transaction. This adapter
///         handles the delegation authorization flow and routes validation through
///         the existing PermissionVault.
///
///         Flow:
///         1. EOA owner signs an EIP-7702 authorization (off-chain)
///         2. Agent submits tx with the authorization
///         3. This adapter verifies the delegation and routes to PermissionVault
///         4. PermissionVault enforces all 15-step validation
///
///         This contract does NOT replace PermissionVault — it wraps it for EOA compatibility.
contract EIP7702Adapter is Ownable, Pausable, EIP712("BouclierEIP7702Adapter", "1") {
    using ECDSA for bytes32;

    // ── EIP-712 typehash for delegation authorization ────────────
    bytes32 public constant DELEGATION_TYPEHASH = keccak256(
        "Delegation(address delegator,address agent,uint256 nonce,uint48 expiry)"
    );

    // ── Dependencies ─────────────────────────────────────────────
    PermissionVault public immutable permissionVault;
    AgentRegistry   public immutable agentRegistry;

    // ── State ────────────────────────────────────────────────────
    // delegator EOA → agent address → active delegation
    struct Delegation {
        bool    active;
        uint48  expiry;
        uint256 nonce;
    }
    mapping(address delegator => mapping(address agent => Delegation)) public delegations;
    mapping(address delegator => uint256) public delegationNonces;

    // ── Events ───────────────────────────────────────────────────
    event DelegationCreated(address indexed delegator, address indexed agent, uint48 expiry);
    event DelegationRevoked(address indexed delegator, address indexed agent);
    event DelegatedValidation(address indexed delegator, address indexed agent, bool allowed);

    // ── Constructor ──────────────────────────────────────────────
    constructor(
        address _admin,
        address _permissionVault,
        address _agentRegistry
    ) Ownable(_admin) {
        permissionVault = PermissionVault(payable(_permissionVault));
        agentRegistry   = AgentRegistry(_agentRegistry);
    }

    // ── Delegation Management ────────────────────────────────────

    /// @notice Create a delegation: EOA owner authorizes an agent to act on their behalf.
    ///         The agent must already be registered in AgentRegistry and have a valid
    ///         PermissionScope in PermissionVault.
    /// @param agent   The agent wallet address
    /// @param expiry  Unix timestamp when this delegation expires
    /// @param signature EIP-712 signature from the delegator (EOA owner)
    function createDelegation(
        address agent,
        uint48  expiry,
        bytes calldata signature
    ) external whenNotPaused {
        require(agent != address(0), "EIP7702Adapter: zero agent address");
        require(expiry > block.timestamp, "EIP7702Adapter: delegation already expired");

        // Verify the agent is registered
        bytes32 agentId = agentRegistry.getAgentId(agent);
        require(agentId != bytes32(0), "EIP7702Adapter: agent not registered");

        // Verify EIP-712 signature from the delegator
        uint256 nonce = delegationNonces[msg.sender]++;
        bytes32 structHash = keccak256(abi.encode(
            DELEGATION_TYPEHASH,
            msg.sender,
            agent,
            nonce,
            expiry
        ));
        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(signature);
        require(signer == msg.sender, "EIP7702Adapter: invalid delegator signature");

        delegations[msg.sender][agent] = Delegation({
            active: true,
            expiry: expiry,
            nonce:  nonce
        });

        emit DelegationCreated(msg.sender, agent, expiry);
    }

    /// @notice Revoke a delegation. Callable by the delegator (EOA owner).
    function revokeDelegation(address agent) external {
        require(delegations[msg.sender][agent].active, "EIP7702Adapter: no active delegation");
        delegations[msg.sender][agent].active = false;
        emit DelegationRevoked(msg.sender, agent);
    }

    /// @notice Validate a delegated operation. Called when an agent attempts to
    ///         execute on behalf of the delegating EOA.
    /// @param delegator The EOA that delegated authority
    /// @param userOp    The UserOp to validate (sender should be the agent)
    /// @param userOpHash Hash of the UserOp
    /// @return validationData 0 = success, 1 = failed
    function validateDelegatedOp(
        address delegator,
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external whenNotPaused returns (uint256 validationData) {
        address agent = userOp.sender;

        // Check delegation exists and is valid
        Delegation storage d = delegations[delegator][agent];
        if (!d.active) {
            emit DelegatedValidation(delegator, agent, false);
            return VALIDATION_FAILED;
        }
        if (block.timestamp > d.expiry) {
            d.active = false; // auto-expire
            emit DelegatedValidation(delegator, agent, false);
            return VALIDATION_FAILED;
        }

        // Delegate to PermissionVault for full 15-step validation
        validationData = permissionVault.validateUserOp(userOp, userOpHash);

        emit DelegatedValidation(delegator, agent, validationData == VALIDATION_SUCCESS);
        return validationData;
    }

    /// @notice Check if a delegation is currently active and not expired.
    function isDelegationActive(address delegator, address agent) external view returns (bool) {
        Delegation storage d = delegations[delegator][agent];
        return d.active && block.timestamp <= d.expiry;
    }

    /// @notice Returns the EIP-712 domain separator.
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    // ── Emergency ────────────────────────────────────────────────
    function pause()   external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
