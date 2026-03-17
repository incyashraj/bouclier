---
sidebar_position: 1
slug: /
---

# What is Bouclier?

Bouclier (French for "shield") is an open-source **trust layer for autonomous AI agents on blockchain**. It gives humans cryptographic control over what their AI agents can do, spend, and access on-chain — with an immutable audit trail built for regulators.

> "Bouclier is the OAuth + IAM layer for autonomous AI agents."

---

## The Problem

17,000+ AI agents operate on-chain today, controlling wallets, executing DeFi trades, and managing DAO treasuries. There is no standard answer to:

- **Who authorised this agent to act?**
- **What is it allowed to do and what is off-limits?**
- **Can the authorisation be revoked instantly?**
- **Is there a verifiable, tamper-proof record of everything it ever did?**

Misconfigured agents have caused tens of millions in losses. Bouclier is the answer.

---

## Protocol Primitives

| Contract | What It Does |
|---|---|
| **AgentRegistry** | Every agent gets a verifiable on-chain DID, status tracking, and hierarchy |
| **PermissionVault** | ERC-7579 validator enforcing granular scopes: protocol allowlist, spend caps, asset whitelist, time windows |
| **SpendTracker** | Rolling-window on-chain accounting with Chainlink price feeds |
| **RevocationRegistry** | Instant cryptographic kill switch with 24h timelock and emergency override |
| **AuditLogger** | Every agent action hashed, timestamped, and optionally anchored to IPFS |

---

## Live Deployments (Base Sepolia)

| Contract | Address |
|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` |

All contracts are source-verified on Basescan (Solidity 0.8.24).

---

## Next Steps

- [**Quickstart**](./quickstart) - integrate Bouclier in 10 minutes
- [**Contracts**](./contracts/overview) - architecture deep-dive
- [**TypeScript SDK**](./sdk/typescript) - full API reference
