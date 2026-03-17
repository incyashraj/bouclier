# Bouclier

> **The Trust Layer for Autonomous AI Agents on Blockchain**

Bouclier is an open-source protocol and SDK that gives humans cryptographic control over what their AI agents can do, spend, and access on-chain — with an immutable audit trail built for regulators.

> "Bouclier is the OAuth + IAM layer for autonomous AI agents on blockchain."

---

## Live Deployments — Base Sepolia (chain 84532)

| Contract | Address | Basescan |
|---|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` | [View ↗](https://sepolia.basescan.org/address/0xc5288f059a1ecdb5e8957fc5c17e86754b7850fb) |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` | [View ↗](https://sepolia.basescan.org/address/0xcba8c42e7e69db1746b0dce4bf6cd58d52c8e0aa) |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` | [View ↗](https://sepolia.basescan.org/address/0xff3107529d7815ea6faaba2b3efc257538d0fbb7) |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` | [View ↗](https://sepolia.basescan.org/address/0xa0bb860ae111dbd0c174e7c8fa17495fce9534e1) |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` | [View ↗](https://sepolia.basescan.org/address/0x42fdfc97cc5937e5c654dfe9494aa278a17d2735) |

All contracts are **source-verified** on Basescan (Pass - Verified, Solidity 0.8.24, 200 runs).

---

## The Problem

17,000+ AI agents operate on-chain today, controlling wallets, executing DeFi trades, and managing DAO treasuries. There is no standard answer to:

- **Who authorised this agent to act?**
- **What is it allowed to do — and what is off-limits?**
- **Can the authorisation be revoked instantly?**
- **Is there a verifiable, tamper-proof record of everything it ever did?**

This is not theoretical. Misconfigured agents have caused tens of millions in losses.

---

## Protocol Primitives

| Contract | What It Does |
|---|---|
| **AgentRegistry** | Every agent gets a verifiable on-chain DID (`did:ethr:base:0x...`), status tracking, and hierarchy |
| **PermissionVault** | ERC-7579 validator enforcing granular scopes: protocol allowlist, spend caps, asset whitelist, time windows |
| **SpendTracker** | Rolling-window on-chain accounting with Chainlink price feed; hard-stops when daily cap exceeded |
| **RevocationRegistry** | Instant cryptographic kill switch with 24h timelock and emergency override |
| **AuditLogger** | Every agent action hashed, timestamped, and optionally anchored to IPFS |

---

## Architecture

```
Human / Enterprise
       │ Permission Grant (EIP-712 signed)
       ▼
┌──────────────────────────────────────────┐
│            BOUCLIER PROTOCOL             │
│  AgentRegistry  PermissionVault  Audit   │
└───────────────────────┬──────────────────┘
                        │ Validates every action
                        ▼
              AI Agent (LangChain / ELIZA / AgentKit)
                        │ Action attempt
                        ▼
┌──────────────────────────────────────────┐
│       PERMISSION ENFORCEMENT LAYER       │
│  ScopeValidator  SpendLimiter  Revoker   │
└───────────────────────┬──────────────────┘
                        │ Allow / Deny + emit AuditEvent
                        ▼
               Blockchain Settlement
```

Full architecture → [architecture/system-overview.md](architecture/system-overview.md)

---

## Quick Start

> Prerequisites: Node 22 LTS, Bun 1.3+, Foundry

```bash
git clone https://github.com/bouclier-protocol/bouclier && cd bouclier
```

### TypeScript SDK

```bash
cd packages/sdk && bun install && bun test   # 13/13 tests
```

```typescript
import { BouclierClient } from "@bouclier/sdk";
import { createPublicClient, http } from "viem";
import { baseSepolia } from "viem/chains";

const client = new BouclierClient({
  chain: baseSepolia,
  rpcUrl: "https://base-sepolia.g.alchemy.com/v2/<KEY>",
  contracts: {
    agentRegistry:    "0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb",
    revocationRegistry: "0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa",
    permissionVault:  "0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7",
    spendTracker:     "0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1",
    auditLogger:      "0x42FDFC97CC5937E5c654dFE9494AA278A17D2735",
  },
});

const agentId = await client.getAgentId("0xYourAgentWallet");
const isRevoked = await client.isRevoked(agentId);
const scope = await client.getActiveScope(agentId);
```

### LangChain Integration

```typescript
import { BouclierCallbackHandler } from "@bouclier/langchain";
import { AgentExecutor } from "langchain/agents";

const handler = new BouclierCallbackHandler(bouclierClient, agentId);
const executor = await AgentExecutor.fromAgentAndTools({ agent, tools,
  callbacks: [handler],   // blocks revoked agents before any LLM call
});
```

### Python SDK

```bash
cd python-sdk && pip install -e ".[dev]" && pytest   # 9/9 tests
```

```python
from bouclier import BouclierClient

client = BouclierClient(
    rpc_url="https://base-sepolia.g.alchemy.com/v2/<KEY>",
    agent_registry="0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb",
    permission_vault="0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7",
    revocation_registry="0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa",
)
agent_id = client.get_agent_id("0xYourAgentWallet")
```

### Smart Contracts

```bash
cd contracts
forge test                          # 84/84 unit tests
forge test --match-path "test/integration/*" \
  --fork-url $BASE_SEPOLIA_RPC_URL  # 7/7 fork tests
```

---

## Framework Adapters

| Package | Framework | Tests |
|---|---|---|
| `@bouclier/langchain` | LangChain (JS) | 10/10 ✅ |
| `@bouclier/eliza-plugin` | ELIZA / ElizaOS | 10/10 ✅ |
| `@bouclier/agentkit` | Coinbase AgentKit | 11/11 ✅ |
| `bouclier-sdk` (Python) | LangChain Python, custom | 9/9 ✅ |

---

## Repository Structure

```
bouclier/
├── contracts/                    # Foundry — 5 Solidity contracts
│   ├── src/                      # IBouclier, AgentRegistry, PermissionVault, etc.
│   ├── test/unit/                # 84 unit tests
│   ├── test/integration/         # 7 fork integration tests
│   ├── test/invariant/           # 9 handler-based invariant tests (128K fuzz calls)
│   ├── specs/                    # 3 Certora formal verification specs + configs
│   ├── audit/                    # Security report, C4 scope, Immunefi bounty
│   ├── script/Deploy.s.sol       # Testnet deploy + verify
│   ├── script/DeployMainnet.s.sol # Base mainnet deploy (Chainlink, safety checks)
│   ├── script/DeployRegistryOnly.s.sol # Ethereum L1 identity anchor
│   └── deployments/              # Canonical address records
├── api/                          # FastAPI SaaS backend (multi-tenant)
│   ├── app/                      # Routes, models, services, auth
│   ├── tests/                    # 14 async API tests
│   ├── alembic/                  # Async database migrations
│   └── docker-compose.yml        # API + PostgreSQL 16 + Redis 7
├── packages/
│   ├── sdk/                      # @bouclier/sdk — TypeScript client
│   ├── langchain/                # @bouclier/langchain — callback handler
│   ├── eliza-plugin/             # @bouclier/eliza-plugin
│   └── agentkit/                 # @bouclier/agentkit — AgentKit wrapper
├── python-sdk/                   # bouclier-sdk — Python client (PyPI)
├── dashboard/                    # Next.js 15 compliance dashboard
├── subgraph/                     # The Graph — 5 data sources, 7 entities
├── bouclier-docs/                # Docusaurus 3 documentation site
├── docs/standards/               # ERC-7579, ERC-4337, DID gap analysis
└── phases/                       # Detailed phase plans (Weeks 1–30)
```

---

## Test Results

| Suite | Result |
|---|---|
| Solidity unit tests | **84/84** |
| Solidity invariant tests (128K fuzz calls) | **9/9** |
| Fork integration tests (Base Sepolia) | **7/7** |
| TypeScript SDK | **13/13** |
| @bouclier/langchain | **10/10** |
| @bouclier/eliza-plugin | **10/10** |
| @bouclier/agentkit | **11/11** |
| Python SDK | **9/9** |
| FastAPI SaaS backend | **19/19** |
| **Total** | **172/172** |

---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Solidity 0.8.24, ERC-7579, ERC-4337, Foundry |
| Identity | W3C DID (`did:ethr:base:`), EIP-712 |
| Chains | Base (primary), Arbitrum, Ethereum |
| TypeScript SDK | viem v2, wagmi v2, TypeScript 5 |
| Python SDK | web3.py 7, eth-account, pydantic v2 |
| Agent Integrations | LangChain, ELIZA, Coinbase AgentKit |
| Indexing | The Graph (AssemblyScript, 5 data sources) |
| Dashboard | Next.js 15, shadcn/ui, wagmi v2, RainbowKit v2 |
| SaaS Backend | FastAPI, SQLAlchemy 2.0 (async), PostgreSQL 16, Redis 7 |
| Compliance | MAS FAA-N16, MiCA Article 38 report generators |
| CI | GitHub Actions (forge test + Slither + tsc) |
| Security | Slither, Mythril, Foundry Invariant, Certora Prover |

---

## Development Status

| Phase | Status | Completion |
|---|---|---|
| 0 — Research & Foundations | 🟢 Complete | 95% |
| 1 — Core Protocol MVP | 🟢 Complete | 100% |
| 2 — Developer Ecosystem | 🟡 In Progress | 85% |
| 3 — Security & Audit | 🟡 In Progress | 65% |
| 4 — Enterprise Pilot | 🟡 In Progress | 25% |
| 5 — Mainnet + Investor | 🔴 Not Started | 0% |

Live tracker → [PROGRESS.md](PROGRESS.md)

**Documentation site:** https://bouclier-docs-nzoz4sbma-incyashrajs-projects.vercel.app

---

## License

MIT — the core protocol is and will remain open-source.

---

*Started: March 2026 · Built at NTU Singapore*
