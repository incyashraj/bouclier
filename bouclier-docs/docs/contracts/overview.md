---
sidebar_position: 1
---

# Contracts Overview

Bouclier is composed of 5 smart contracts deployed on Base Sepolia (chain 84532). Each handles a distinct responsibility — together they form a composable trust layer.

## Deployed Addresses (Base Sepolia)

| Contract | Address | Basescan |
|---|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` | [View ↗](https://sepolia.basescan.org/address/0xc5288f059a1ecdb5e8957fc5c17e86754b7850fb) |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` | [View ↗](https://sepolia.basescan.org/address/0xff3107529d7815ea6faaba2b3efc257538d0fbb7) |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` | [View ↗](https://sepolia.basescan.org/address/0xcba8c42e7e69db1746b0dce4bf6cd58d52c8e0aa) |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` | [View ↗](https://sepolia.basescan.org/address/0xa0bb860ae111dbd0c174e7c8fa17495fce9534e1) |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` | [View ↗](https://sepolia.basescan.org/address/0x42fdfc97cc5937e5c654dfe9494aa278a17d2735) |

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
