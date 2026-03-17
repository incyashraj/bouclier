<p align="center">
  <strong>Bouclier</strong><br/>
  The trust layer for autonomous AI agents on-chain.
</p>

<p align="center">
  <a href="https://bouclier.eth.limo">Website</a> · <a href="https://bouclier.eth.limo/docs">Docs</a> · <a href="https://bouclier.eth.limo/pricing">Pricing</a> · <a href="https://bouclier.eth.limo/developers">Developers</a>
</p>

---

## What is Bouclier?

Bouclier gives every AI agent a verifiable on-chain identity, enforceable permission scopes, spend limits, and an immutable audit trail — so humans stay in control of what autonomous agents can do.

Think of it as **IAM for AI agents on blockchain**.

| Capability | What it does |
|---|---|
| **Agent Identity** | On-chain DID for every agent with status tracking and hierarchy |
| **Permission Scopes** | ERC-7579 validator enforcing protocol allowlists, asset whitelists, and time windows |
| **Spend Limits** | Rolling-window accounting with Chainlink price feeds and hard stops when caps are exceeded |
| **Instant Revocation** | Cryptographic kill switch with 24-hour timelock and emergency override |
| **Audit Trail** | Every action hashed, timestamped, and optionally anchored to IPFS |

Deployed and verified on **Base Sepolia**. Targeting Base mainnet.

---

## Get Started

### Install the SDK

```bash
npm install @bouclier/sdk
```

### Register and monitor an agent — TypeScript

```typescript
import { BouclierClient } from "@bouclier/sdk";
import { baseSepolia } from "viem/chains";

const bouclier = new BouclierClient({
  chain: baseSepolia,
  rpcUrl: process.env.BASE_RPC_URL,
});

// Check agent status
const agentId = await bouclier.getAgentId("0xAgentWallet");
const isRevoked = await bouclier.isRevoked(agentId);
const scope = await bouclier.getActiveScope(agentId);
```

### Register and monitor an agent — Python

```bash
pip install bouclier-sdk
```

```python
from bouclier import BouclierClient

client = BouclierClient(rpc_url="https://sepolia.base.org")
agent_id = client.get_agent_id("0xAgentWallet")
scope = client.get_active_scope(agent_id)
```

### Framework integrations

Drop Bouclier into your existing agent framework with one line:

```typescript
// LangChain
import { BouclierCallbackHandler } from "@bouclier/langchain";
const executor = AgentExecutor.fromAgentAndTools({
  agent, tools,
  callbacks: [new BouclierCallbackHandler(bouclier, agentId)],
});

// Coinbase AgentKit
import { BouclierAgentKit } from "@bouclier/agentkit";
const kit = new BouclierAgentKit(bouclier, agentId, baseKit);

// ELIZA / ElizaOS
import { bouclierPlugin } from "@bouclier/eliza-plugin";
const agent = new ElizaAgent({ plugins: [bouclierPlugin(bouclier)] });
```

---

## How It Works

```
       Human / Enterprise
              |
              |  EIP-712 signed permission grant
              v
   +---------------------+
   |   BOUCLIER PROTOCOL |    <- On-chain smart contracts
   |                     |       (open source, permissionless)
   +----------+----------+
              |
              |  Validates every action against scopes,
              |  spend limits, and revocation status
              v
       AI Agent (any framework)
              |
              |  Action -> Allow / Deny + AuditEvent
              v
       Blockchain Settlement
```

1. **Grant** — Human signs a scoped permission (protocols, assets, caps, expiry) via EIP-712.
2. **Enforce** — Every agent action is validated on-chain before execution.
3. **Audit** — Each action emits a tamper-proof event with full context.
4. **Revoke** — Kill switch available instantly in emergencies, or via 24h timelock.

---

## Pricing

Bouclier is **open-source and permissionless**. The core protocol will always be free.

| | Open Protocol | Bouclier Cloud | Enterprise |
|---|---|---|---|
| **Price** | **Free** | **Usage-based** | **Custom** |
| Agent registration | Gas only | Included | Included |
| Policy deployment | Gas only | Included | Included |
| On-chain verification | Gas only | Included | Included |
| Audit trail | On-chain | On-chain + indexed API | On-chain + dedicated API |
| Managed sentinel nodes | — | Included | Dedicated |
| Compliance dashboard | — | Included | White-label |
| Monitoring & alerts | — | Included | Custom rules |
| Compliance reports (MiCA, MAS) | — | — | Included |
| Custom policy development | — | — | Included |
| SLA & priority support | — | — | Included |

**Open Protocol** — Self-host everything. Deploy contracts, run your own nodes, use the SDKs. You pay only gas on Base L2 (typically < $0.01 per transaction).

**Bouclier Cloud** — Managed infrastructure so you don't have to run anything. Hosted sentinel nodes, indexed query API, real-time dashboard, and alerts. Usage-based pricing — pay for what you verify.

**Enterprise** — Dedicated infrastructure, custom SLAs, compliance report generation for regulated environments (MiCA Article 38, MAS FAA-N16), white-label dashboard, and direct engineering support.

→ [bouclier.eth.limo/pricing](https://bouclier.eth.limo/pricing)

---

## Smart Contracts

All contracts are source-verified on Basescan. Solidity 0.8.24, built with Foundry.

| Contract | Address | |
|---|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` | [Basescan ↗](https://sepolia.basescan.org/address/0xc5288f059a1ecdb5e8957fc5c17e86754b7850fb) |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` | [Basescan ↗](https://sepolia.basescan.org/address/0xff3107529d7815ea6faaba2b3efc257538d0fbb7) |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` | [Basescan ↗](https://sepolia.basescan.org/address/0xa0bb860ae111dbd0c174e7c8fa17495fce9534e1) |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` | [Basescan ↗](https://sepolia.basescan.org/address/0xcba8c42e7e69db1746b0dce4bf6cd58d52c8e0aa) |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` | [Basescan ↗](https://sepolia.basescan.org/address/0x42fdfc97cc5937e5c654dfe9494aa278a17d2735) |

---

## SDKs & Packages

| Package | Language | Install |
|---|---|---|
| `@bouclier/sdk` | TypeScript | `npm install @bouclier/sdk` |
| `@bouclier/langchain` | TypeScript | `npm install @bouclier/langchain` |
| `@bouclier/eliza-plugin` | TypeScript | `npm install @bouclier/eliza-plugin` |
| `@bouclier/agentkit` | TypeScript | `npm install @bouclier/agentkit` |
| `bouclier-sdk` | Python | `pip install bouclier-sdk` |

---

## Why Bouclier?

**For agent developers** — Ship agents that enterprises actually trust. Add verifiable permissions in minutes, not weeks.

**For enterprises** — Deploy AI agents with cryptographic guardrails. Every action is scoped, spend-limited, revocable, and auditable.

**For regulators** — Tamper-proof on-chain audit trail with compliance report generation against MiCA and MAS frameworks.

---

## Security

- Static analysis via Slither on every commit
- Symbolic execution via Mythril
- Invariant testing with 128K+ fuzz calls via Foundry
- Property-based fuzzing via Echidna (10M iterations)
- Formal verification with Certora Prover — 15 rules verified, 0 violations
- Fork integration tests against live Base Sepolia

Report vulnerabilities → [Security Advisories](https://github.com/incyashraj/bouclier/security/advisories)

---

## Contributing

Bouclier is open source under the MIT license. Contributions are welcome.

```bash
git clone https://github.com/incyashraj/bouclier.git
```

Full developer documentation → [bouclier.eth.limo/docs](https://bouclier.eth.limo/docs)

---

## License

MIT
