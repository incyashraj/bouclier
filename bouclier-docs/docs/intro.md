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
| AgentRegistry | `0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB` |
| PermissionVault | `0xe0b283A4Dff684E5D700E53900e7B27279f7999F` |
| RevocationRegistry | `0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270` |
| SpendTracker | `0x930Eb18B9962c30b388f900ba9AE62386191cD48` |
| AuditLogger | `0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE` |

All contracts are source-verified on Basescan (Solidity 0.8.24).

---

## Next Steps

- [**Quickstart**](./quickstart) - integrate Bouclier in 10 minutes
- [**Contracts**](./contracts/overview) - architecture deep-dive
- [**TypeScript SDK**](./sdk/typescript) - full API reference
