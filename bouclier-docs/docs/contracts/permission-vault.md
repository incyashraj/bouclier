---
sidebar_position: 3
---

# PermissionVault

`PermissionVault.sol` is the enforcement engine. It implements ERC-7579 `IValidator` and executes a 15-step validation on every agent action.

**Address (Base Sepolia):** `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7`

---

## Write Functions

### `grantPermission`

```solidity
function grantPermission(
    bytes32 agentId,
    PermissionScope calldata scope,
    bytes calldata ownerSignature
) external
```

Grants a permission scope to an agent. Requires a valid EIP-712 signature from the agent's owner. Emits `PermissionGranted`.

### `revokePermission`

```solidity
function revokePermission(bytes32 agentId) external
```

Revokes the active scope for an agent. Only the agent's owner can call this.

### `emergencyRevoke`

```solidity
function emergencyRevoke(bytes32 agentId) external
```

Revokes immediately and also calls `RevocationRegistry.revoke()`. Can be called by the owner or any `GUARDIAN_ROLE` holder.

### `validateUserOp` (ERC-7579)

```solidity
function validateUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash
) external returns (uint256 validationData)
```

The hot path. Called by the ERC-4337 EntryPoint. Returns `0` on success, `1` on failure.

**15-step validation:**

1. Decode `callData` → `target`, `selector`, `value`, `tokenAddress`, `amount`
2. Resolve `agentId` from `AgentRegistry`
3. Check agent is `ACTIVE`
4. Check agent is not revoked (`RevocationRegistry`)
5. Load active scope
6. Check scope is not revoked
7. Check time window (`validFrom` ≤ `now` ≤ `validUntil`)
8. Check protocol allowlist (`target` ∈ `allowedProtocols` OR `allowAnyProtocol`)
9. Check selector allowlist (`selector` ∈ `allowedSelectors`)
10. Check token allowlist (`tokenAddress` ∈ `allowedTokens` OR `allowAnyToken`)
11. Check day-of-week window mask
12. Compute USD value via Chainlink
13. Check per-tx spend cap
14. Check rolling daily spend cap
15. **Pass:** record spend + log action → return `0`

Any failure emits `PermissionViolation` with `violationType` string.

## Read Functions

### `getActiveScope`

```solidity
function getActiveScope(bytes32 agentId) external view returns (PermissionScope memory)
```

## PermissionScope Struct

```solidity
struct PermissionScope {
    address[] allowedProtocols;   // contract addresses agent may call
    bytes4[]  allowedSelectors;   // function selectors allowed
    address[] allowedTokens;      // ERC-20 tokens agent may spend
    uint256   perTxSpendCapUSD;   // max USD per single transaction (18 decimals)
    uint256   dailySpendCapUSD;   // rolling 24h USD cap (18 decimals)
    uint48    validFrom;          // unix timestamp scope becomes active
    uint48    validUntil;         // unix timestamp scope expires
    uint8     windowDaysMask;     // bitmask: bit 0=Mon … bit 6=Sun (0=any day)
    bool      allowAnyProtocol;   // skip protocol allowlist check
    bool      allowAnyToken;      // skip token allowlist check
    bool      revoked;            // set to true on revokePermission
}
```

## Events

```solidity
event PermissionGranted(bytes32 indexed agentId, bytes32 indexed grantHash, uint48 validUntil);
event PermissionViolation(bytes32 indexed agentId, address indexed target, string violationType);
```
