# ERC-7579 Gap Analysis for AI Agent Use Cases

> **Standard:** [ERC-7579: Minimal Modular Smart Accounts](https://eips.ethereum.org/EIPS/eip-7579)  
> **Analyst:** Bouclier Protocol  
> **Date:** 2026-03-18  
> **Status:** Complete

---

## Overview

ERC-7579 defines a minimal interface for modular smart account implementations. It separates account logic into **modules** (validators, executors, hooks, fallbacks) which can be installed and removed independently. Bouclier implements `IValidator` from ERC-7579 in `PermissionVault.sol`.

---

## How Bouclier Uses ERC-7579

### Interface Implemented

`PermissionVault` implements `IValidator`:

```solidity
function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
    external returns (uint256 validationData);

function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)
    external view returns (bytes4 magicValue);
```

### Module Type

- **Type 1 — Validator:** `PermissionVault` acts as a stateful validator. It does not modify account storage directly; the smart account EOA/kernel installs it as a validator module.
- Install/uninstall hooks (`onInstall`, `onUninstall`) are implemented as no-ops (storage tied to agentId, not account installation state).

---

## Gaps and Design Decisions

### Gap 1: ERC-7579 vs ERC-4337 `validateUserOp` Return Value

ERC-7579's `IValidator.validateUserOp` returns a `uint256` identical to ERC-4337's `IAccount.validateUserOp`:

| Bits | Meaning |
|---|---|
| Bit 0 | `1` = signature validation failed (FAIL) |
| Bits 1–159 | `authorizer` address (0 = no paymaster) |
| Bits 160–207 | `validUntil` (0 = unlimited) |
| Bits 208–255 | `validFrom` (0 = immediately) |

**Bouclier implementation:** Returns `SIG_VALIDATION_FAILED (1)` on any policy violation, `0` on success. The `validFrom`/`validUntil` are NOT packed into the return value — they are enforced inside `validateUserOp` as explicit reverts. This is stricter (reverts vs soft-fail) but consistent with how on-chain enforcement should work for agent policies.

**Decision:** Keep current design. Packing `validUntil` into return would allow EntryPoint to cache valid windows; since Bouclier scopes can be revoked any time, an explicit revert is safer.

### Gap 2: Module Context — No `moduleTypeId` Encoding on Install

ERC-7579 requires `IERC7579Module.onInstall(bytes calldata data)` to receive `moduleTypeId` encoded in `data`. Bouclier's `onInstall` ignores the data parameter — it uses the `agentId` bound at `grantPermission` time, not at install time.

**Consequence:** A strict ERC-7579 account implementation that validates `moduleTypeId` in `onInstall` data will fail. Most kernel implementations (Kernel v3, Safe7579) do NOT validate this strictly.

**Decision:** Accept for now. For Phase 3 (audit hardening), update `onInstall` to decode a `(bytes32 agentId)` from the install data and pre-register the binding.

### Gap 3: `isValidSignatureWithSender` — ERC-1271 Stub

Bouclier's `isValidSignatureWithSender` returns `0xffffffff` (invalid) in all cases. This is intentional: Bouclier is not a signature-delegation module; all signing is done by the agent owner via EIP-712 scopes.

**Consequence:** Any module that calls ERC-1271 validation through `PermissionVault` will fail. This is acceptable since Bouclier is a spend/permission guard, not an account ownership validator.

### Gap 4: ERC-6900 vs ERC-7579 — Why We Chose 7579

| Feature | ERC-6900 | ERC-7579 |
|---|---|---|
| Complexity | Higher — mandatory manifest, dependency graph | Minimal — only 4 module types |
| Adoption | Lower (fewer live accounts) | Growing (Kernel v3, Safe7579, Rhinestone) |
| Permissioned install | Required — user approves each module dependency | Optional |
| Hook support | Built-in, complex | Optional IHook module |
| Gas overhead | Higher (manifest reads) | Lower |

**Decision:** ERC-7579's minimal interface is better suited for an AI agent trust layer deployed at scale. ERC-6900's richer manifest system would add gas overhead without benefit for Bouclier's validation-only use case.

### Gap 5: EIP-7702 (EOA Extension) — Future Compatibility

EIP-7702 allows an EOA to temporarily delegate to a contract implementation (set `code[EOA] = delegateTo(contract)`). This would allow AI agent EOAs to become ERC-7579 accounts without a separate smart account wallet.

**Current status:** EIP-7702 is in "Review" status. Base Sepolia support: not yet confirmed.

**Decision:** Phase 2 feature. `PermissionVault` is already compatible — it validates by `agentId` (a `bytes32`), not by account address. When EIP-7702 is available, agents can point their EOA code at an ERC-7579 account that installs `PermissionVault` as validator.

### Gap 6: Execution Module — Bouclier Does Not Implement IExecutor

Bouclier validates but does not execute. The AI agent's smart account (e.g., Kernel v3) handles execution. `PermissionVault`'s job is done once `validateUserOp` returns `0`.

**Decision:** Correct and intentional. Mixing validation and execution in one module would violate separation of concerns and make formal verification harder.

---

## Chainlink Integration Note (SpendTracker)

SpendTracker uses `AggregatorV3Interface`. Key observations:

- All Base Sepolia feeds return **8 decimals** (not 18). Conversion: `answer * 10**10` to normalize to 18-decimal USD.
- `latestRoundData()` returns `(roundId, answer, startedAt, updatedAt, answeredInRound)`. Bouclier checks `updatedAt >= block.timestamp - 3600` (stale check) and `answer > 0` (negative price guard).
- Base Sepolia feed addresses differ from Base mainnet. See `Constants.sol` for test addresses; production deployment should read from `deployments/base-sepolia.json`.

---

## Summary

Bouclier implements ERC-7579 IValidator correctly for the agent-permission use case. The three gaps identified (module context, ERC-1271 stub, EIP-7702) are intentional design decisions appropriate for Phase 0/1 and noted for Phase 2–3 resolution.
