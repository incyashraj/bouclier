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

// Query audit trail — everything this agent did
const eventIds = await bouclier.getAgentHistory(agentId, 0n, 50n);
const record = await bouclier.getAuditRecord(eventIds[0]);
console.log(record.target, record.allowed, record.timestamp);
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

# Full audit trail — returns hydrated AuditRecord objects
trail = client.get_audit_trail(agent_id, offset=0, limit=100)
for event in trail:
    print(event.target, event.allowed, event.usd_amount)
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
| AgentRegistry | `0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB` | [Basescan ↗](https://sepolia.basescan.org/address/0x4b23841a1cd67b1489d6d84d2dce666ddef4ccdb) |
| PermissionVault | `0xe0b283A4Dff684E5D700E53900e7B27279f7999F` | [Basescan ↗](https://sepolia.basescan.org/address/0xe0b283a4dff684e5d700e53900e7b27279f7999f) |
| SpendTracker | `0x930Eb18B9962c30b388f900ba9AE62386191cD48` | [Basescan ↗](https://sepolia.basescan.org/address/0x930eb18b9962c30b388f900ba9ae62386191cd48) |
| RevocationRegistry | `0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270` | [Basescan ↗](https://sepolia.basescan.org/address/0x759833b7eea1df45ad2b2f22b56bee6cc5227270) |
| AuditLogger | `0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE` | [Basescan ↗](https://sepolia.basescan.org/address/0x8e30a7ec6ba7c767535b0e178e002d354f7335ce) |

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

## Bouclier vs Alternatives

| | Bouclier | Safe Guards | Fireblocks / Fordefi | Roll your own |
|---|---|---|---|---|
| **Agent-native identity** | On-chain DID per agent with hierarchy | No — guards are per-Safe, not per-agent | Off-chain API keys | Manual mapping |
| **Permission scopes** | EIP-712 signed, on-chain enforced (protocols, assets, caps, expiry) | Transaction-level checks only — no scoped grants | Proprietary policy engine, off-chain | Custom modifiers |
| **Spend limits** | Rolling-window with Chainlink oracles, USD-denominated | ETH-only or no native support | USD limits but custodial | Self-built |
| **Revocation** | Instant emergency + 24h timelock, on-chain registry | Remove guard (admin tx) | API call (centralized) | Custom |
| **Audit trail** | Every action hashed on-chain + IPFS anchoring | Events only | Centralized logs | Whatever you build |
| **Modular accounts** | ERC-7579 validator module — composable with any modular account | Safe-only | Vendor lock-in | N/A |
| **Open source** | Yes — MIT license, permissionless | Guard logic open, but Safe-coupled | No | N/A |
| **Multi-framework** | LangChain, AgentKit, ELIZA integrations | None | None | Manual |

Safe Guards solve transaction filtering for multisigs. Custodial MPC vaults (Fireblocks, Fordefi) solve key management. Bouclier solves **agent permission management** — scoped identity, enforcement, audit, and revocation as a composable on-chain protocol that works across any ERC-4337/7579 account and any agent framework.

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
