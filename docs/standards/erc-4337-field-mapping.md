# ERC-4337 UserOp Field Mapping — Bouclier Validation Logic

> **Standard:** [ERC-4337: Account Abstraction Using Alt Mempool](https://eips.ethereum.org/EIPS/eip-4337) v0.7 (PackedUserOperation)  
> **Analyst:** Bouclier Protocol  
> **Date:** 2026-03-18  
> **Status:** Complete

---

## PackedUserOperation Struct (v0.7)

ERC-4337 v0.7 replaced the flat `UserOperation` struct with `PackedUserOperation`, which packs gas fields to reduce calldata cost by ~10%.

```solidity
struct PackedUserOperation {
    address sender;         // The smart account address
    uint256 nonce;          // Sender's nonce (includes key in upper 192 bits)
    bytes   initCode;       // initCode for account creation (empty if exists)
    bytes   callData;       // Encoded call to execute
    bytes32 accountGasLimits; // Packed: [verificationGasLimit(16) | callGasLimit(16)]
    uint256 preVerificationGas;
    bytes32 gasFees;        // Packed: [maxPriorityFeePerGas(16) | maxFeePerGas(16)]
    bytes   paymasterAndData; // Paymaster address + data (empty = no paymaster)
    bytes   signature;      // Validator signature (opaque bytes passed to IValidator)
}
```

> **Note:** v0.6 had separate `verificationGasLimit`, `callGasLimit`, `maxPriorityFeePerGas`, `maxFeePerGas` fields. v0.7 packs them into `accountGasLimits` and `gasFees`. Bouclier uses the v0.7 struct via the `account-abstraction` library (`@eth-infinitism/account-abstraction@v0.7`).

---

## How Bouclier Uses Each Field

| Field | Used By | How | Notes |
|---|---|---|---|
| `sender` | `PermissionVault.validateUserOp` | Resolved to `agentId` via `AgentRegistry.getAgentId(sender)` | The smart account address of the AI agent |
| `nonce` | Not directly used | Nonce is managed by EntryPoint, not PermissionVault | PermissionVault has its own EIP-712 scope nonce |
| `initCode` | Not used | Account creation is out of scope for v1 | Future: could trigger auto-registration on first deploy |
| `callData` | `PermissionVault.validateUserOp` | Decoded: `callData[0:4]` = selector, `callData[4:24]` = target address | Used to check allowlist and extract `usdAmount` |
| `accountGasLimits` | Not used | Gas limit validation is EntryPoint's job | |
| `preVerificationGas` | Not used | EntryPoint handles | |
| `gasFees` | Not used | EntryPoint handles | |
| `paymasterAndData` | Not used | Out of scope for v1 | Future: Bouclier paymaster for gasless agent ops |
| `signature` | `PermissionVault.validateUserOp` | EIP-712 scope signature from owner | Decoded and verified against `SCOPE_TYPEHASH` |

---

## `callData` Decoding in `validateUserOp`

```
callData layout (ERC-4337 standard execute call):
  bytes[0:4]   = bytes4 selector         <- PermissionVault reads this
  bytes[4:24]  = address target          <- PermissionVault reads this
  bytes[24:56] = uint256 value           <- ETH value (not used in v1)
  bytes[56:]   = bytes data              <- Inner call data (not decoded in v1)
```

`PermissionVault._extractTarget(callData)`:
```solidity
function _extractTarget(bytes calldata cd) internal pure returns (address target, bytes4 sel) {
    sel = bytes4(cd[:4]);
    target = address(bytes20(cd[4:24]));
}
```

This target+selector pair is checked against the agent's `PermissionScope`:
- `allowAnyProtocol = false` → target must be in `allowedProtocols` mapping
- `allowAnyToken = false` → token derived from callData must be in `allowedTokens`

---

## `signature` Field Layout

The `signature` field in Bouclier's `PackedUserOperation` contains the EIP-712 signed `PermissionScope`:

```
signature layout:
  bytes[0:65]  = ECDSA signature (r, s, v) of the PermissionScope struct hash
```

This is the agent owner's signature over:

```
SCOPE_TYPEHASH = keccak256(
  "PermissionScope(bytes32 agentId,uint256 nonce,uint256 dailySpendCapUSD,"
  "uint256 perTxSpendCapUSD,uint48 validFrom,uint48 validUntil,"
  "bool allowAnyProtocol,bool allowAnyToken)"
)
```

**Key design decision:** The signature is created by the **agent's human owner** (not the agent itself). The agent presents this signed scope in its UserOp. `PermissionVault` verifies that the signer matches the owner registered in `AgentRegistry` for the given `agentId`.

---

## Nonce Design

ERC-4337 v0.7 nonce format:
```
nonce = (key << 64) | seq
```
- `key` (upper 192 bits): multi-dimensional nonce key, chosen by account
- `seq` (lower 64 bits): sequential counter per key, maintained by EntryPoint

Bouclier's EIP-712 scope nonce is **separate** from the UserOp nonce:
- UserOp nonce: managed by EntryPoint (prevents replay of UserOps)
- Scope nonce: stored in `PermissionVault._scopeNonces[agentId]`, prevents reuse of signed `PermissionScope` structs

When `grantPermission` is called, the scope nonce is consumed. A new signed scope must be provided for the next permission grant.

---

## `userOpHash` Parameter

`validateUserOp(userOp, userOpHash)` — the `userOpHash` is:
```
keccak256(abi.encode(keccak256(packUserOp(userOp)), entryPoint, chainId))
```
Computed by EntryPoint before calling the validator.

**Bouclier does not use `userOpHash` directly** — all verification is done by decoding `userOp.signature` and checking it against the stored `PermissionScope` hash. The `userOpHash` is available but not needed since Bouclier's authorization model is scope-based, not per-userOp.

---

## v0.6 vs v0.7 Migration Notes

If you see `UserOperation` (v0.6) in older code:

| v0.6 field | v0.7 equivalent |
|---|---|
| `verificationGasLimit` | upper 16 bytes of `accountGasLimits` |
| `callGasLimit` | lower 16 bytes of `accountGasLimits` |
| `maxPriorityFeePerGas` | upper 16 bytes of `gasFees` |
| `maxFeePerGas` | lower 16 bytes of `gasFees` |
| `initCode` | `initCode` (same, but factory+data if creating) |

Bouclier's `IBouclier.sol` re-exports `PackedUserOperation` from the `account-abstraction` v0.9 library which targets EntryPoint v0.7.

---

## Summary

Bouclier uses `sender`, `callData`, and `signature` from `PackedUserOperation`. Gas fields are EntryPoint concerns. The scope-based authorization model means validation cost is dominated by `ecrecover` + storage reads (estimated ~50K gas for a full `validateUserOp` with spend check).
