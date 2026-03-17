# Bouclier — Technical Due Diligence Package

> Prepared for investor evaluation. Contains verified technical facts only — no projections.
> Last Updated: March 2026

---

## 1. Protocol Overview

Bouclier is an on-chain trust layer for AI agents. It enforces permission scopes, spend caps, and revocation controls at the smart contract level (ERC-7579 validator module), blocking unauthorized transactions before they execute.

**Architecture:** 5 Solidity smart contracts working together:

| Contract | Purpose | Lines of Code |
|---|---|---|
| `PermissionVault.sol` | ERC-7579 validator — 15-step `validateUserOp` | Core enforcement |
| `AgentRegistry.sol` | DID-based agent identity (`did:ethr:base:0x…`) | Identity layer |
| `RevocationRegistry.sol` | Kill switch with 24h timelock + emergency bypass | Revocation |
| `SpendTracker.sol` | Chainlink oracle + sliding window ring buffer | Spend caps |
| `AuditLogger.sol` | Append-only audit trail with IPFS CID support | Compliance |

**Standards compliance:** ERC-4337 (Account Abstraction), ERC-7579 (Modular Accounts), EIP-712 (Typed Signatures), W3C DID Core

---

## 2. Codebase Statistics

| Metric | Value |
|---|---|
| Solidity contracts | 5 production + 1 interface + 2 harness |
| Solidity pragma | 0.8.24 (compiled with solc 0.8.28) |
| Build tool | Foundry 1.5.1 |
| Dependencies | OpenZeppelin 5.6.1, Chainlink |
| TypeScript SDK | `@bouclier/sdk` v0.1.0 (viem v2) |
| Python SDK | `bouclier-sdk` v0.1.0 (web3.py ≥7) |
| Framework adapters | LangChain, ELIZA, Coinbase AgentKit |
| Total test count | **172 tests across 7 suites — all passing** |

### Test Breakdown

| Suite | Count | Framework |
|---|---|---|
| Solidity unit tests | 84 | Foundry |
| Solidity invariant tests | 9 (128K fuzz calls each) | Foundry |
| Fork integration tests | 7 | Foundry (Base Sepolia fork) |
| TypeScript SDK tests | 13 | Bun test |
| Framework adapter tests | 31 (10+10+11) | Bun test |
| Python SDK tests | 9 | pytest |
| FastAPI SaaS tests | 19 | pytest |
| **Total** | **172** | |

---

## 3. Security Audit Status

### Automated Analysis — Zero Findings

| Tool | Type | Result |
|---|---|---|
| **Slither v0.11.5** | Static analysis | 4 findings fixed → **0 remaining** |
| **Mythril v0.24.8** | Symbolic execution | 5/5 contracts → **0 real vulnerabilities** |
| **Foundry invariant** | Property-based fuzzing | 9/9 properties hold at 128K calls |

### Formal Verification — Certora Prover

| Spec | Rules | Verified | Key Properties |
|---|---|---|---|
| SpendTracker | 4 | **4/4** | Spend cap enforcement, rolling monotonicity, zero-cap = unlimited |
| RevocationRegistry | 6 | **6/6** | Revoke sets flag, reinstate respects 24h timelock, idempotent revoke |
| PermissionVault | 9 | **9/9** | Paused→revert, binary return, scope revocation, nonce monotonicity, DOMAIN_SEPARATOR immutability |
| **Total** | **19** | **19/19** | |

### Hardening Measures Implemented

- [x] ReentrancyGuard on PermissionVault.validateUserOp
- [x] Checks-effects-interactions pattern throughout
- [x] EIP-712 SCOPE_TYPEHASH includes nonce field (bug found + fixed pre-audit)
- [x] Oracle circuit breaker: 5% deviation threshold with refreshable anchor
- [x] Chainlink heartbeat check: MAX_FEED_AGE = 3600s
- [x] No `selfdestruct`, no `delegatecall` to untrusted, no `tx.origin`
- [x] All contracts implement `Pausable` (emergency kill switch)
- [x] Access Control Matrix documented (function × role × modifier)

### Pending (Post-Funding)

- [ ] Code4rena competitive audit (~$15K prize pool)
- [ ] Immunefi bug bounty ($100K reserve)

---

## 4. Deployment Status

### Base Sepolia (Testnet) — Live + Verified

| Contract | Address | Basescan |
|---|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` | ✅ Verified |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` | ✅ Verified |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` | ✅ Verified |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` | ✅ Verified |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` | ✅ Verified |

### Mainnet Deployment Scripts (Written, Not Executed)

- `DeployMainnet.s.sol` — Base mainnet (Chainlink ETH/USD + USDC/USD feeds, admin≠deployer safety, auto role revocation)
- `DeployRegistryOnly.s.sol` — Ethereum L1 identity anchor

### Monitoring

- Tenderly: 5/5 contracts imported for transaction monitoring
- The Graph subgraph: deployed to Graph Studio (7 entities, 5 data sources)

---

## 5. Published Packages

| Package | Registry | Version | Link |
|---|---|---|---|
| `@bouclier/sdk` | npm | 0.1.0 | https://www.npmjs.com/package/@bouclier/sdk |
| `@bouclier/langchain` | npm | 0.1.0 | https://www.npmjs.com/package/@bouclier/langchain |
| `@bouclier/eliza-plugin` | npm | 0.1.0 | https://www.npmjs.com/package/@bouclier/eliza-plugin |
| `@bouclier/agentkit` | npm | 0.1.0 | https://www.npmjs.com/package/@bouclier/agentkit |
| `bouclier-sdk` | PyPI | 0.1.0 | https://pypi.org/project/bouclier-sdk/0.1.0/ |

---

## 6. Infrastructure

| Component | Technology | Status |
|---|---|---|
| Smart contracts | Foundry + Solidity 0.8.24 | Production |
| TypeScript SDK | viem v2 + TypeScript | Published |
| Python SDK | web3.py + pydantic v2 | Published |
| Dashboard | Next.js 15 + wagmi v2 + RainbowKit | Deployed (Vercel) |
| Subgraph | The Graph (AssemblyScript) | Deployed (Graph Studio) |
| SaaS API | FastAPI + SQLAlchemy + Alembic | Built (Docker-ready) |
| Compliance | MAS FAA-N16 + MiCA Art. 38 generators | Built |
| CI/CD | GitHub Actions (forge test + Slither + fmt) | Active |
| Docs | Docusaurus 3 | Deployed (Vercel) |

---

## 7. Repository Structure

```
bouclier/
├── contracts/          # Foundry project — 5 Solidity contracts + tests
│   ├── src/            # Production contracts
│   ├── test/           # Unit + integration + invariant tests
│   ├── script/         # Deploy scripts (testnet + mainnet)
│   ├── specs/          # Certora CVL specs + harness contracts
│   └── audit/          # Security report + access control matrix
├── packages/
│   ├── sdk/            # @bouclier/sdk (TypeScript)
│   ├── langchain/      # @bouclier/langchain adapter
│   ├── eliza-plugin/   # @bouclier/eliza-plugin
│   └── agentkit/       # @bouclier/agentkit adapter
├── python-sdk/         # bouclier-sdk (Python/PyPI)
├── dashboard/          # Next.js compliance dashboard
├── subgraph/           # The Graph indexer
├── api/                # FastAPI SaaS backend
├── bouclier-docs/      # Docusaurus documentation site
├── business/           # Investor materials + financial model
├── phases/             # Development phase plans (0–5)
└── docs/               # EIP draft + standards analysis
```

**GitHub:** https://github.com/incyashraj/bouclier

---

## 8. Key Technical Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Bug in `validateUserOp` bypasses enforcement | Critical | Certora 19/19 verified + Slither + Mythril + 84 unit tests |
| Oracle manipulation bypasses USD caps | High | Circuit breaker (5% deviation), heartbeat check, admin-refreshable anchor |
| ERC-4337 adoption stalls | Medium | EIP-7702 provides alternative path for EOAs |
| Competitor copies open-source contracts | Medium | EIP submission for standard lock-in + SaaS layer is proprietary |
| Smart contract upgrade needed | Low | Immutable contracts by design; new version = new deploy + migration |

---

*Confidential — prepared for investor due diligence.*
