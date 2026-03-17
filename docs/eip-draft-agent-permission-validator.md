# EIP-XXXX: Standard Interface for AI Agent Permission Validation

**Author:** Yashraj Pardeshi  
**Status:** Draft  
**Type:** Standards Track (ERC)  
**Category:** ERC  
**Created:** 2026-03-17  
**Requires:** EIP-712, ERC-7579

---

## Abstract

This EIP proposes a standard interface — `IAgentPermissionValidator` — for on-chain permission validation of autonomous AI agents. It defines a minimal, composable interface that any ERC-7579-compatible smart account module can implement to enforce cryptographically-scoped authorisation for agent-initiated user operations.

The interface standardises:
1. How permission scopes are structured and signed (EIP-712)
2. How scopes are granted, stored, and revoked
3. How validation is signalled to an ERC-4337 EntryPoint

---

## Motivation

Autonomous AI agents are increasingly used to control wallets, execute DeFi trades, manage DAO treasuries, and act as on-chain representatives of human principals. As of 2026, there are over 17,000 active AI agents operating on EVM-compatible chains, with no standard for:

- **Scope definition**: What actions is an agent authorised to take?
- **Spend controls**: How much value can an agent move per transaction or per day?
- **Revocation**: How can authorisation be instantly cancelled?
- **Auditability**: How can a third party verify what an agent was permitted to do?

Without a standard, every protocol implementing agent controls takes a different approach, preventing composability and tooling integration. This EIP proposes a minimal standard that can be adopted as an ERC-7579 validator module, enabling any smart account to add AI agent controls without bespoke integration.

---

## Specification

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

### Core Data Structures

```solidity
/// @notice Defines the permission boundaries for an AI agent.
struct PermissionScope {
    /// @dev Contracts the agent is allowed to invoke. Empty = use allowAnyProtocol.
    address[] allowedProtocols;

    /// @dev 4-byte function selectors the agent may call. Empty = allow all.
    bytes4[] allowedSelectors;

    /// @dev ERC-20 token addresses the agent may spend. Empty = use allowAnyToken.
    address[] allowedTokens;

    /// @dev Maximum USD value (18 decimals) for a single transaction.
    uint256 perTxSpendCapUSD;

    /// @dev Maximum USD value (18 decimals) for a rolling 24-hour window.
    uint256 dailySpendCapUSD;

    /// @dev Unix timestamp when the scope becomes active.
    uint48 validFrom;

    /// @dev Unix timestamp when the scope expires.
    uint48 validUntil;

    /// @dev Bitmask for allowed days of week. Bit 0 = Monday, bit 6 = Sunday. 0 = all days.
    uint8 windowDaysMask;

    /// @dev If true, allowedProtocols is ignored and any target is permitted.
    bool allowAnyProtocol;

    /// @dev If true, allowedTokens is ignored.
    bool allowAnyToken;

    /// @dev Set to true when the scope is revoked.
    bool revoked;
}
```

### `IAgentPermissionValidator`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";

/// @title IAgentPermissionValidator
/// @notice ERC-7579 validator module interface for AI agent permission enforcement.
/// @dev Implement this interface to enforce cryptographic permission scopes on
///      agent-initiated user operations. Compliant with ERC-4337 v0.7.
interface IAgentPermissionValidator {

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a permission scope is granted to an agent.
    event PermissionGranted(
        bytes32 indexed agentId,
        bytes32 indexed scopeHash,
        uint48  validUntil
    );

    /// @notice Emitted when a permission scope is revoked.
    event PermissionRevoked(bytes32 indexed agentId, address indexed revokedBy);

    /// @notice Emitted when an agent action is blocked.
    event PermissionViolation(
        bytes32 indexed agentId,
        address indexed target,
        string  violationType
    );

    // -------------------------------------------------------------------------
    // Write
    // -------------------------------------------------------------------------

    /// @notice Grants a permission scope to an agent.
    /// @dev MUST verify ownerSignature is a valid EIP-712 signature over the
    ///      PermissionScope by the agent's registered owner.
    /// @param agentId       The unique identifier of the agent.
    /// @param scope         The permission scope to grant.
    /// @param ownerSignature EIP-712 signature from the agent's owner.
    function grantPermission(
        bytes32 agentId,
        PermissionScope calldata scope,
        bytes calldata ownerSignature
    ) external;

    /// @notice Revokes the active permission scope for an agent.
    /// @dev MUST only be callable by the agent's registered owner or an
    ///      authorised guardian role.
    /// @param agentId The unique identifier of the agent to revoke.
    function revokePermission(bytes32 agentId) external;

    // -------------------------------------------------------------------------
    // ERC-4337 / ERC-7579 Validation
    // -------------------------------------------------------------------------

    /// @notice Validates a user operation against the agent's active permission scope.
    /// @dev Called by the ERC-4337 EntryPoint. MUST:
    ///      1. Decode userOp.callData to extract target, selector, tokenAddress, amount.
    ///      2. Check the agent is not globally revoked.
    ///      3. Validate all fields of the active PermissionScope.
    ///      4. On pass: record spend and log the action.
    ///      5. Return SIG_VALIDATION_SUCCESS (0) on full pass.
    ///      6. Return SIG_VALIDATION_FAILED (1) on any constraint violation.
    ///      7. Emit PermissionViolation with an appropriate violationType string on failure.
    /// @param userOp     The packed user operation.
    /// @param userOpHash The hash of the user operation.
    /// @return validationData 0 = success, 1 = failure.
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);

    // -------------------------------------------------------------------------
    // Read
    // -------------------------------------------------------------------------

    /// @notice Returns the active permission scope for an agent.
    function getActiveScope(bytes32 agentId) external view returns (PermissionScope memory);

    /// @notice Returns true if the agent has an active, non-revoked, non-expired scope.
    function hasActivePermission(bytes32 agentId) external view returns (bool);
}
```

### Violation Type Registry

Implementations SHOULD use the following standardised `violationType` strings in `PermissionViolation` events:

| `violationType` | Meaning |
|---|---|
| `"AGENT_REVOKED"` | Agent is globally revoked |
| `"AGENT_INACTIVE"` | Agent status is not ACTIVE |
| `"SCOPE_REVOKED"` | Active scope has been revoked |
| `"SCOPE_EXPIRED"` | `block.timestamp > scope.validUntil` |
| `"SCOPE_NOT_STARTED"` | `block.timestamp < scope.validFrom` |
| `"PROTOCOL_NOT_ALLOWED"` | `target` not in `allowedProtocols` |
| `"SELECTOR_NOT_ALLOWED"` | `selector` not in `allowedSelectors` |
| `"TOKEN_NOT_ALLOWED"` | `tokenAddress` not in `allowedTokens` |
| `"PERTX_CAP_EXCEEDED"` | USD value exceeds `perTxSpendCapUSD` |
| `"DAILY_CAP_EXCEEDED"` | Rolling 24h USD volume exceeds `dailySpendCapUSD` |
| `"WINDOW_DAY_BLOCKED"` | Current day of week blocked by `windowDaysMask` |

### EIP-712 Domain and Type Hash

Implementations MUST use the following EIP-712 type for scope signing:

```
PermissionScope(
    address[] allowedProtocols,
    bytes4[] allowedSelectors,
    address[] allowedTokens,
    uint256 perTxSpendCapUSD,
    uint256 dailySpendCapUSD,
    uint48 validFrom,
    uint48 validUntil,
    uint8 windowDaysMask,
    bool allowAnyProtocol,
    bool allowAnyToken
)
```

The EIP-712 domain MUST include:
- `name`: implementation-defined string
- `version`: implementation-defined string
- `chainId`: `block.chainid`
- `verifyingContract`: the `IAgentPermissionValidator` contract address

---

## Rationale

### Why ERC-7579 rather than a standalone interface?

ERC-7579 modular smart accounts are the emerging standard for extensible smart wallets. By implementing `IAgentPermissionValidator` as an ERC-7579 validator module, any ERC-7579-compatible account (Safe, Kernel, Biconomy Nexus, etc.) can add AI agent controls without forking the account contract.

### Why include spend caps in the interface?

Spend caps are the single most requested control mechanism for AI agents, and their omission from existing access control standards is a key security gap. Including USD-denominated caps in the scope struct ensures that any compliant implementation exposes this control.

### Why USD rather than token-denominated caps?

Token-denominated caps break when prices move (an agent permitted to spend 1 ETH has very different real-world power at $1,000/ETH vs $10,000/ETH). USD caps, converted via a trusted oracle, provide stable economic intent.

### Why `violationType` strings rather than error codes?

Strings are more expressive in events (which are indexed off-chain) and allow new violation types to be added without a registry update. The standardised strings in this EIP allow tooling (dashboards, compliance systems) to interpret violations across implementations without custom adapters.

---

## Backwards Compatibility

This EIP introduces a new interface and is fully additive. It has no impact on existing contracts.

Implementations MAY omit the spend cap enforcement (setting `perTxSpendCapUSD` and `dailySpendCapUSD` to `type(uint256).max`) to maintain compatibility with environments that do not have a price oracle.

---

## Reference Implementation

The reference implementation is the Bouclier Protocol, deployed on Base Sepolia:

- `PermissionVault` (IAgentPermissionValidator): `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7`
- Source code: https://github.com/bouclier-protocol/bouclier
- Basescan: https://sepolia.basescan.org/address/0xff3107529d7815ea6faaba2b3efc257538d0fbb7

All 5 Bouclier contracts are source-verified. The implementation passes 76/76 unit tests and 7/7 fork integration tests on Base Sepolia.

---

## Security Considerations

### Oracle Manipulation

Implementations using price oracles for USD-denominated spend caps MUST enforce a maximum staleness threshold (recommended: 3600 seconds). Flash loan price manipulation attacks do not affect oracle-based spend cap calculations when using external heartbeat feeds (e.g. Chainlink).

### Scope Signing Key Compromise

If a scope-signing key is compromised, the owner can revoke the active scope immediately via `revokePermission`. The agent then requires a new scope grant before it can act again.

### Reinstatement Race Condition

Implementations SHOULD enforce a time delay between revocation and reinstatement (recommended: 86400 seconds) to prevent a compromised owner from immediately re-activating a malicious agent.

### Re-entrancy in `validateUserOp`

Implementations MUST protect `validateUserOp` against re-entrancy. The recommended pattern is to update state (record spend, log action) after all external reads and before returning.

---

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
