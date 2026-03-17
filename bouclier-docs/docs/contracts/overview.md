---
sidebar_position: 1
---

# Contracts Overview

Bouclier is composed of 5 smart contracts deployed on Base Sepolia (chain 84532). Each handles a distinct responsibility — together they form a composable trust layer.

## Deployed Addresses (Base Sepolia)

| Contract | Address | Basescan |
|---|---|---|
| AgentRegistry | `0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB` | [View ↗](https://sepolia.basescan.org/address/0x4b23841a1cd67b1489d6d84d2dce666ddef4ccdb) |
| PermissionVault | `0xe0b283A4Dff684E5D700E53900e7B27279f7999F` | [View ↗](https://sepolia.basescan.org/address/0xe0b283a4dff684e5d700e53900e7b27279f7999f) |
| RevocationRegistry | `0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270` | [View ↗](https://sepolia.basescan.org/address/0x759833b7eea1df45ad2b2f22b56bee6cc5227270) |
| SpendTracker | `0x930Eb18B9962c30b388f900ba9AE62386191cD48` | [View ↗](https://sepolia.basescan.org/address/0x930eb18b9962c30b388f900ba9ae62386191cd48) |
| AuditLogger | `0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE` | [View ↗](https://sepolia.basescan.org/address/0x8e30a7ec6ba7c767535b0e178e002d354f7335ce) |

All contracts are **source-verified** on Basescan (Solidity 0.8.24, optimizer 200 runs).

---

## Architecture

```
AgentRegistry ──────────────────────────────────┐
                                                 │
RevocationRegistry ──────────────────────────── PermissionVault
                                                 │   (ERC-7579 IValidator)
SpendTracker ────────────────────────────────────┘
                                                 │
AuditLogger ◄────────────────────────────────────┘
```

**Flow:**
1. Owner calls `AgentRegistry.register()` → agent gets a DID and `agentId`
2. Owner signs an EIP-712 `PermissionScope` and calls `PermissionVault.grantPermission()`
3. On every action, `PermissionVault.validateUserOp()` checks all 15 validation steps
4. On pass: `SpendTracker.recordSpend()` + `AuditLogger.logAction()` called atomically
5. Owner calls `RevocationRegistry.revoke()` to instantly block all future actions

---

## Standards Compliance

| Standard | Implementation |
|---|---|
| [ERC-7579](https://eips.ethereum.org/EIPS/eip-7579) | `PermissionVault` implements `IValidator.validateUserOp` |
| [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) | `PackedUserOperation` handled in `validateUserOp` |
| [EIP-712](https://eips.ethereum.org/EIPS/eip-712) | Permission scope signing in `PermissionVault` |
| [W3C DID Core](https://www.w3.org/TR/did-core/) | `AgentRegistry` generates `did:ethr:base:0x{address}` |
| [Chainlink Data Feeds](https://docs.chain.link/data-feeds) | `SpendTracker` uses on-chain USD pricing |

---

## Test Coverage

| Contract | Unit Tests | Notes |
|---|---|---|
| RevocationRegistry | 15 | REVOKER_ROLE, GUARDIAN_ROLE, 24h timelock |
| AgentRegistry | 12 | DID generation, hierarchy, reverse lookup |
| SpendTracker | 14 | Chainlink oracle, sliding window ring buffer |
| AuditLogger | 10 | IPFS CID anchoring, append-only invariant |
| PermissionVault | 25 | ERC-7579, 15-step validateUserOp |
| **Total** | **76/76** | + 7/7 fork integration tests |
