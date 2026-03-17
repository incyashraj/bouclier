# Bouclier — The Trust Layer for Autonomous AI Agents on Blockchain
### A Complete Startup Blueprint for NTU MSc Blockchain Students (2026)

---

## Table of Contents

1. [The Problem — In Full Detail](#1-the-problem)
2. [The Solution — What We Build](#2-the-solution)
3. [Why Now — Market Timing](#3-why-now)
4. [Technical Architecture](#4-technical-architecture)
5. [Full Tech Stack](#5-full-tech-stack)
6. [Product Breakdown — All Primitives](#6-product-breakdown)
7. [Smart Contract Design](#7-smart-contract-design)
8. [How the System Works End-to-End](#8-how-the-system-works)
9. [Security Model](#9-security-model)
10. [Data Model & Storage](#10-data-model--storage)
11. [API Design](#11-api-design)
12. [12-Month Technical Roadmap](#12-12-month-technical-roadmap)
13. [Business Model](#13-business-model)
14. [Go-To-Market Strategy](#14-go-to-market-strategy)
15. [Competitive Landscape](#15-competitive-landscape)
16. [Team & Hiring Plan](#16-team--hiring-plan)
17. [Funding Strategy](#17-funding-strategy)
18. [Risk Analysis](#18-risk-analysis)
19. [MSc Thesis Angle](#19-msc-thesis-angle)
20. [Appendix — Key Standards & References](#20-appendix)

---

## 1. The Problem

### The Core Gap

Over **17,000 AI agents** currently operate on-chain, controlling wallets, executing DeFi trades, managing DAO treasuries, and interacting with smart contracts autonomously. The total value they touch daily runs into the **billions of dollars**.

Yet there is **no standard answer** to any of the following questions:

- Who authorised this agent to act?
- What is it allowed to do — and what is explicitly off-limits?
- If it spends funds outside its mandate, who is liable?
- Can the authorisation be revoked instantly if something goes wrong?
- Is there a verifiable, tamper-proof record of everything the agent ever did?

This is not a theoretical risk. It is an active, daily attack surface.

### Why This Is Worse Than It Sounds

In traditional software security, a compromised service account is bad. In blockchain, it is **irreversible**. There are no chargebacks. There is no fraud department. A misconfigured AI agent with an open-ended wallet approval can drain an entire protocol treasury in a single transaction — and no human may notice for minutes.

**Key failure modes observed in 2025–2026:**

| Failure Type | Example | Loss |
|---|---|---|
| Agent with unlimited wallet approval | AI agent given `approve(MAX_UINT256)` calls drain function | $47M |
| No revocation mechanism | Compromised agent key, no kill switch | $23M |
| Unsigned task provenance | Agent claimed to execute a strategy it didn't | Regulatory investigation |
| Scope creep | Agent authorised for one protocol, accessed five | Protocol DAO vote collapse |
| Multi-agent confusion | Agent A delegated to Agent B without human oversight | $8M lost to circular trades |

### The Structural Reason Nobody Has Solved This

This problem sits at the intersection of three deep disciplines:

1. **Cryptographic identity systems** — decentralised identifiers (DIDs), verifiable credentials
2. **Smart contract security engineering** — modular accounts, permission scopes, ERC-7579
3. **AI agent architecture** — how LLM-based agents plan, execute, and communicate

Almost no team has genuine depth in all three simultaneously. Most Web3 security firms don't understand agent architectures. Most AI companies don't think in terms of on-chain permissions. The gap is a talent gap as much as a technology gap.

---

## 2. The Solution

### What We Build: AgentShield

**AgentShield** is an open-source protocol + enterprise SaaS platform that provides:

1. **Agent Identity Standard** — every AI agent gets a verifiable on-chain identity (DID-based)
2. **Permission Scopes** — granular, human-readable rules defining what an agent can and cannot do
3. **Spending Rails** — hard on-chain caps on what an agent can spend, per period, per protocol
4. **Revocation Protocol** — instant, cryptographically verifiable kill switch
5. **Immutable Audit Trail** — every agent action is hashed, timestamped, and anchored on-chain
6. **Compliance Dashboard** — human-readable interface for enterprises and regulators

### The One-Sentence Pitch

> "AgentShield is the OAuth + IAM layer for autonomous AI agents on blockchain — giving humans cryptographic control over what their agents can do, spend, and access, with an immutable audit trail built for regulators."

### What "OAuth for Agents" Actually Means

OAuth solved a specific problem in Web2: instead of giving a third-party app your password, you grant it a scoped token with specific permissions (read email, but not delete). The key insight is **delegation without full trust transfer**.

AgentShield does the same for on-chain agents:

```
Human/Enterprise  →  grants scoped permission token  →  AI Agent
                      (protocol: Uniswap only)
                      (spend cap: $500/day)
                      (expiry: 7 days)
                      (revocable: yes)
```

The agent never has unconditional access. Every action it takes is bounded by a permission scope that is cryptographically verifiable by anyone.

---

## 3. Why Now

### Market Timing Signals (2026)

**On the AI agent side:**
- LLM agents (Claude, GPT-4o, Llama 4) are now production-quality for multi-step autonomous tasks
- Agent frameworks (LangChain, AutoGPT, ELIZA, CrewAI) have hit mainstream developer adoption
- Coinbase's AgentKit, GOAT SDK, and Alchemy's AA SDK all provide "wallets for agents" but have NO permission layer

**On the regulatory side:**
- **EU AI Act (fully effective 2026)** — requires audit trails for high-risk AI systems. Financial AI agents are explicitly high-risk.
- **MAS (Singapore)** — published guidelines in 2025 on AI governance for financial institutions, explicitly noting autonomous agent risks
- **US SEC** — increasing scrutiny of AI-driven trading with no human oversight documentation

**On the infrastructure side:**
- ERC-7579 (modular smart accounts) is now widely adopted — gives us the hook point for permission modules
- EIP-7702 (EOA as smart account) means even simple wallets can now be extended with our permission logic
- EigenLayer's AVS framework lets us build a decentralised validation network for agent actions cheaply

### The Window

This is a **12–18 month window**. Once a VC-backed team with $20M raises specifically to solve this, the standard race begins. Right now, the space is open. An MSc student publishing a credible open standard on GitHub in 2026 can own the narrative before capital floods in.

---

## 4. Technical Architecture

### High-Level System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        HUMAN / ENTERPRISE                        │
│                  (Creates agent, sets permissions)               │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Permission Grant (signed tx)
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AGENTSHIELD PROTOCOL                          │
│                                                                  │
│  ┌─────────────────┐   ┌──────────────────┐   ┌─────────────┐  │
│  │  Agent Registry  │   │  Permission Vault │   │ Audit Logger│  │
│  │  (DID + metadata)│   │  (ERC-7579 module)│   │ (on-chain)  │  │
│  └────────┬────────┘   └────────┬─────────┘   └──────┬──────┘  │
│           │                     │                     │          │
│           └─────────────────────┴─────────────────────┘         │
│                                 │                                │
└─────────────────────────────────┼────────────────────────────────┘
                                  │ Validates every action
                                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                        AI AGENT                                  │
│  (LangChain / ELIZA / Custom)                                    │
│  Agent attempts: sign tx, call protocol, transfer funds          │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Action attempt
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                   PERMISSION ENFORCEMENT LAYER                   │
│  ┌────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│  │ Scope Validator │  │ Spend Rate Limiter│  │ Revocation Check │ │
│  │ (allowed proto) │  │ (daily cap logic) │  │ (on-chain flag)  │ │
│  └────────────────┘  └──────────────────┘  └──────────────────┘ │
└──────────────────────────┬──────────────────────────────────────┘
                           │  Allow / Deny + log
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BLOCKCHAIN SETTLEMENT                          │
│         (Base / Arbitrum / Ethereum mainnet)                     │
└─────────────────────────────────────────────────────────────────┘
```

### Architectural Layers

| Layer | What It Does | Key Tech |
|---|---|---|
| Identity Layer | Assigns and resolves agent DIDs | W3C DID, did:ethr, did:key |
| Permission Layer | Stores and enforces scopes | ERC-7579 module, smart contracts |
| Enforcement Layer | Validates every action pre-execution | ERC-4337 UserOp validation |
| Audit Layer | Immutable log of all agent actions | On-chain event logs + IPFS |
| Revocation Layer | Kill switch + credential invalidation | On-chain flag + EIP-5564 |
| Compliance Layer | Human-readable dashboard + export | Next.js SaaS, The Graph |
| SDK Layer | Developer tooling | TypeScript SDK, Python SDK |

---

## 5. Full Tech Stack

### Blockchain / Smart Contract Layer

| Technology | Version | Purpose |
|---|---|---|
| **Solidity** | 0.8.24+ | Core smart contract language |
| **ERC-7579** | Final | Modular smart account standard — foundation for permission modules |
| **EIP-7702** | Active | Allows EOAs to temporarily behave as smart accounts |
| **ERC-4337** | v0.7 | Account abstraction — UserOp flow for agent transactions |
| **ERC-6900** | Draft | Alternative modular account standard (implement both for coverage) |
| **Base L2** | — | Primary deployment chain (low gas, Coinbase ecosystem, AgentKit integration) |
| **Arbitrum One** | — | Secondary chain (DeFi ecosystem) |
| **Ethereum mainnet** | — | Anchor chain for high-value identity records |
| **Foundry** | Latest | Smart contract development, testing, fuzzing |
| **OpenZeppelin** | v5 | Audited contract libraries |

### Identity & Credentials Layer

| Technology | Purpose |
|---|---|
| **W3C DID Core spec** | Foundation standard for agent identifiers |
| **did:ethr** | Ethereum-anchored DID method — each agent gets `did:ethr:base:0x...` |
| **Verifiable Credentials (VC)** | W3C standard for expressing permission grants as signed JSON-LD |
| **JSON-LD** | Linked data format for credential schemas |
| **IPFS / Filecoin** | Off-chain storage of credential metadata and audit logs |

### Agent Integration Layer

| Technology | Purpose |
|---|---|
| **LangChain** | Most popular agent framework — primary integration target |
| **ELIZA Framework** | Web3-native agent framework — high priority |
| **AutoGPT / CrewAI** | Secondary integration targets |
| **Coinbase AgentKit** | Direct SDK integration — their wallet, our permission layer |
| **GOAT SDK** | On-chain action library for agents |
| **viem** | TypeScript Ethereum library for agent transaction construction |
| **ethers.js v6** | Alternative, widely used in existing agent code |

### Backend Infrastructure

| Technology | Version | Purpose |
|---|---|---|
| **TypeScript** | 5.x | Primary SDK language |
| **Python** | 3.12+ | Secondary SDK (ML ecosystem) |
| **Node.js** | 20 LTS | SDK runtime + API server |
| **FastAPI** | 0.110+ | Compliance API server (Python) |
| **PostgreSQL** | 16 | Off-chain indexing of agent activity |
| **Redis** | 7 | Rate limiting, session cache, real-time revocation cache |
| **The Graph** | — | On-chain event indexing for audit trail queries |
| **Subgraph Studio** | — | Deploy + manage subgraphs |

### Frontend / Dashboard

| Technology | Purpose |
|---|---|
| **Next.js 15** | Compliance dashboard + developer portal |
| **React 19** | UI framework |
| **Tailwind CSS** | Styling |
| **shadcn/ui** | Component library |
| **wagmi v2** | Web3 wallet connection |
| **RainbowKit** | Wallet UI kit |
| **Recharts** | Analytics charts for audit dashboard |
| **Vercel** | Hosting |

### Security & ZK Layer

| Technology | Purpose |
|---|---|
| **EZKL** | ZK proofs for ML inference (prove an AI produced an output) |
| **Risc Zero** | General-purpose zkVM for verifiable computation |
| **TEE (TDX / SGX)** | Trusted Execution Environments for sensitive model execution |
| **Semaphore** | ZK identity protocol (useful for anonymous agent credential checks) |
| **Noir** | ZK circuit language for custom proofs |

### DevOps & Infrastructure

| Technology | Purpose |
|---|---|
| **GitHub Actions** | CI/CD pipeline |
| **Docker** | Containerisation |
| **AWS** | Cloud infrastructure (Singapore region for MAS compliance) |
| **Datadog** | Monitoring + alerting |
| **Tenderly** | Smart contract monitoring, simulation, alerting |
| **Alchemy / QuickNode** | RPC providers |

---

## 6. Product Breakdown — All Primitives

### Primitive 1: Agent Identity Registry

**What it is:** A smart contract registry that assigns and resolves unique, verifiable identities to AI agents.

**How it works:**
1. Developer calls `AgentRegistry.register(agentAddress, metadata)` 
2. Contract emits `AgentRegistered(did, agentAddress, owner, timestamp)`
3. Agent receives a DID: `did:ethr:base:0xAGENT_ADDRESS`
4. Metadata (model name, version, creator organisation) stored on IPFS, hash anchored on-chain

**Key fields per agent identity:**
```json
{
  "did": "did:ethr:base:0x1234...abcd",
  "owner": "0xENTERPRISE_ADDRESS",
  "model": "claude-sonnet-4-6",
  "model_hash": "sha256:abc...",
  "created_at": 1748000000,
  "status": "active",
  "permission_vault": "0xPERMISSION_VAULT_ADDRESS",
  "metadata_ipfs": "ipfs://Qm..."
}
```

---

### Primitive 2: Permission Vault (Core Product)

**What it is:** An ERC-7579 smart account module that enforces granular permission scopes for every agent action.

**Permission scope types:**

| Scope Type | Example | Enforcement |
|---|---|---|
| Protocol allowlist | `["uniswap_v3", "aave_v3"]` | Checks target contract against list |
| Spend cap (daily) | `$500 USDC/day` | Tracks cumulative spend in rolling 24h window |
| Spend cap (per-tx) | `max $200 per tx` | Checks each UserOp value |
| Asset whitelist | `["USDC", "ETH", "WBTC"]` | Rejects txs touching other tokens |
| Time window | `Mon–Fri 09:00–18:00 UTC` | Validates block timestamp |
| Callable functions | `["swap()", "addLiquidity()"]` only | Function selector check |
| Chain scope | `Base only` | Cross-chain message validation |
| Destination whitelist | Specific contract addresses only | Target address check |

**Permission grant structure (Solidity pseudocode):**
```solidity
struct PermissionScope {
    bytes32 agentId;           // Agent's DID hash
    address[] allowedProtocols;
    bytes4[] allowedSelectors; // Function selectors
    address[] allowedTokens;
    uint256 dailySpendCap;     // In USD equivalent (Chainlink oracle)
    uint256 perTxSpendCap;
    uint32 validFrom;
    uint32 validUntil;
    bool revoked;
    bytes32 grantHash;         // Hash of full grant for auditing
}
```

---

### Primitive 3: Spending Rate Limiter

**What it is:** On-chain accounting that tracks agent spending across a rolling time window and hard-stops transactions that exceed caps.

**How it works:**
- Uses a sliding window algorithm (not a fixed daily reset — prevents gaming)
- Denominated in USD via Chainlink price oracles
- Separate limits: per-transaction, hourly, daily, weekly
- Each limit breach triggers: transaction revert + audit event + optional alert to human operator

---

### Primitive 4: Revocation Protocol

**What it is:** A cryptographically verifiable, instant kill switch for any agent.

**Two revocation mechanisms:**

1. **Soft revocation** — sets `revoked = true` in on-chain registry. All permission checks query this flag. Zero-latency via Redis cache mirror.

2. **Hard revocation** — calls `PermissionVault.emergencyRevoke(agentId)` which:
   - Immediately invalidates all active UserOps in the mempool signed by this agent
   - Sets spend caps to zero
   - Burns the agent's session keys
   - Emits `AgentRevoked(agentId, revokedBy, reason, timestamp)` event

**Revocation latency target:** < 2 seconds from human action to agent being unable to execute.

---

### Primitive 5: Immutable Audit Trail

**What it is:** An append-only, tamper-evident log of every action taken by every agent.

**Each audit record contains:**
```json
{
  "event_id": "0xHASH",
  "agent_did": "did:ethr:base:0x...",
  "action_type": "swap",
  "input_params": {"token_in": "USDC", "token_out": "ETH", "amount": 100},
  "target_protocol": "uniswap_v3",
  "tx_hash": "0x...",
  "block_number": 12345678,
  "timestamp": 1748000000,
  "permission_scope_id": "scope_xyz",
  "outcome": "success",
  "gas_used": 142000
}
```

**Storage strategy:**
- Full record stored on IPFS (permanent, content-addressed)
- IPFS hash + minimal metadata stored on-chain (cheap, immutable anchor)
- The Graph subgraph indexes all events for fast querying
- Enterprise customers can export full audit CSV via dashboard API

---

### Primitive 6: Compliance Dashboard (SaaS Product)

**What it is:** A web application that gives enterprises and regulators a human-readable view of all agent activity.

**Key screens:**
1. **Agent inventory** — all registered agents, their status, owner, model, last active
2. **Permission manager** — create/edit/revoke permission scopes via drag-and-drop UI
3. **Live activity feed** — real-time stream of agent actions with accept/flag/revoke controls
4. **Audit explorer** — searchable, filterable audit trail with CSV/JSON export
5. **Anomaly alerts** — AI-powered detection of unusual agent behaviour patterns
6. **Regulatory export** — one-click MAS / MiCA compliant audit report generation

---

## 7. Smart Contract Design

### Contract Architecture

```
AgentShieldCore (proxy, upgradeable)
├── AgentRegistry.sol
│   ├── register(address agent, bytes metadata) → bytes32 did
│   ├── resolve(bytes32 did) → AgentRecord
│   └── updateStatus(bytes32 did, Status status)
│
├── PermissionVault.sol  [ERC-7579 Module]
│   ├── grantPermission(bytes32 agentId, PermissionScope scope) → bytes32 scopeId
│   ├── checkPermission(bytes32 agentId, bytes calldata userOp) → bool
│   ├── revokePermission(bytes32 scopeId)
│   └── emergencyRevoke(bytes32 agentId)
│
├── SpendTracker.sol
│   ├── recordSpend(bytes32 agentId, uint256 usdAmount, uint32 timestamp)
│   ├── checkSpendCap(bytes32 agentId, uint256 proposed) → bool
│   └── getRollingSpend(bytes32 agentId, uint32 windowSeconds) → uint256
│
├── AuditLogger.sol
│   ├── logAction(bytes32 agentId, bytes32 actionHash, string ipfsCid)
│   └── getActionCount(bytes32 agentId) → uint256
│
└── RevocationRegistry.sol
    ├── revoke(bytes32 agentId, string reason)
    ├── isRevoked(bytes32 agentId) → bool
    └── getRevocationRecord(bytes32 agentId) → RevocationRecord
```

### ERC-7579 Module Integration

ERC-7579 defines a standard for modular smart accounts. Our `PermissionVault` is built as a **validator module** — it hooks into the account's `validateUserOp` function:

```solidity
// PermissionVault.sol — ERC-7579 Validator Module
contract PermissionVault is IValidator {
    
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256 validationData) {
        
        bytes32 agentId = agentIdFromUserOp(userOp);
        
        // 1. Check agent is registered and not revoked
        require(!revocationRegistry.isRevoked(agentId), "Agent revoked");
        
        // 2. Check permission scope
        PermissionScope memory scope = getActiveScope(agentId);
        require(isWithinScope(userOp, scope), "Out of scope");
        
        // 3. Check spend cap
        uint256 usdValue = getUsdValue(userOp);
        require(spendTracker.checkSpendCap(agentId, usdValue), "Spend cap exceeded");
        
        // 4. Record spend + log action
        spendTracker.recordSpend(agentId, usdValue, uint32(block.timestamp));
        auditLogger.logAction(agentId, userOpHash, "");
        
        return SIG_VALIDATION_SUCCESS; // or failure packed data
    }
}
```

### Gas Optimisation Strategy

- Use `mapping` over arrays for O(1) lookups on hot paths
- Pack `PermissionScope` struct to fit in 3 storage slots
- Use `block.timestamp` with 5-minute granularity (not per-second) for spend windows — saves SLOAD costs
- Cache revocation status in an immutable `bytes32` bitfield where possible
- Off-chain signature for permission grants (EIP-712), on-chain only for enforcement

---

## 8. How the System Works End-to-End

### Scenario: Enterprise DeFi Agent

**Setup phase (one-time):**

```
1. Company registers on AgentShield dashboard
2. Creates AI agent:  POST /agents  →  receives DID: did:ethr:base:0xAGENT
3. Defines permission scope:
   - Allowed protocols: Uniswap v3, Aave v3
   - Spend cap: $2,000 USDC/day, $500/tx max
   - Asset whitelist: USDC, ETH, WBTC only
   - Time window: 08:00–20:00 UTC, weekdays only
   - Expiry: 90 days
4. Signs and broadcasts permission grant tx on Base
5. PermissionVault.sol stores scope on-chain
6. Company integrates AgentShield SDK into their LangChain agent
```

**Runtime phase (every action):**

```
Agent decides to swap $300 USDC → ETH on Uniswap
  ↓
AgentShield SDK intercepts the UserOp before broadcast
  ↓
SDK calls PermissionVault.checkPermission(agentId, userOp)
  ↓
Vault checks:
  ✓ Agent registered and active
  ✓ Uniswap v3 is in allowed protocols
  ✓ USDC and ETH in asset whitelist
  ✓ $300 < $500 per-tx cap
  ✓ Daily rolling spend = $800, $800 + $300 = $1,100 < $2,000 cap
  ✓ Current time 14:30 UTC Wednesday → within window
  ↓
Permission: GRANTED
  ↓
UserOp broadcast to mempool → executed → tx confirmed
  ↓
AuditLogger records: agentId, txHash, swap params, timestamp, outcome
  ↓
Event indexed by The Graph subgraph
  ↓
Dashboard shows activity in real-time
```

**Revocation scenario:**

```
Human operator sees unusual pattern in dashboard (multiple rapid trades)
  ↓
Clicks "Emergency Revoke" on Agent XYZ
  ↓
Frontend calls:  RevocationRegistry.revoke(agentId, "Unusual activity")
  ↓
On-chain revocation flag set in < 3s
  ↓
Redis cache updated immediately (< 100ms propagation)
  ↓
Any pending UserOps from this agent: REJECTED by PermissionVault
  ↓
Audit trail records revocation event with operator's address and reason
  ↓
Operator receives Slack/email notification with full incident summary
```

---

## 9. Security Model

### Threat Model

| Threat | Attack Vector | Mitigation |
|---|---|---|
| Agent key compromise | Private key stolen from agent runtime | Session keys + spending caps limit blast radius |
| Permission scope bypass | Malicious calldata encoding to pass selector check | Deep calldata validation, not just 4-byte selector |
| Oracle manipulation | Chainlink price feed attack to inflate USD spend cap | Multi-oracle aggregation, deviation checks, TWAP |
| Replay attacks | Re-broadcasting old UserOps | Nonce tracking in PermissionVault |
| Reentrancy | Malicious callback during action validation | Checks-Effects-Interactions, ReentrancyGuard |
| Governance attack | Attacker gains control of registry | Timelocked multisig owner, no single admin key |
| Front-running revocation | Attacker sees revocation tx in mempool, front-runs | Revocation goes through Flashbots Protect MEV |
| Social engineering | Human operator tricked into granting wide permissions | UI friction for dangerous scope combinations |

### Audit Strategy

- **Automated:** Slither, Mythril, Echidna (fuzzing) run on every PR
- **Formal verification:** Certora Prover for critical functions (checkPermission, revokeAgent)
- **Pre-launch audit:** Trail of Bits or OpenZeppelin Audits (budget: $80–150k)
- **Bug bounty:** Immunefi program, $250k max payout, from day one of mainnet

### Session Key Architecture

Agents never hold the primary wallet key. Instead:

```
Master Key (Hardware Wallet, controlled by human)
    │
    └──signs──▶  Session Key Grant (scoped, time-limited, revocable)
                      │
                      └──signs──▶  Agent's Session Key
                                        │
                                        └──executes──▶  Transactions
                                                        (within scopes only)
```

Session keys are EIP-7702-compatible ephemeral signing keys. Even if stolen, they can only execute within the pre-defined permission scope.

---

## 10. Data Model & Storage

### On-Chain Storage (Minimal, Hot)

Only store what must be on-chain for enforcement:
- Agent registration record (address → DID mapping)
- Permission scope hash (not full scope — saves gas)
- Rolling spend accumulators
- Revocation flags

### Off-Chain Storage (IPFS, Permanent)

- Full permission scope JSON
- Full audit records
- Agent metadata (model name, version, description)
- Compliance reports

### Database (PostgreSQL, Indexed)

Used for the SaaS dashboard — mirrors on-chain data for fast querying:

```sql
-- Core tables
agents (id, did, owner_address, model, created_at, status)
permission_scopes (id, agent_id, scope_json, valid_from, valid_until, revoked)
audit_events (id, agent_id, tx_hash, action_type, params_json, outcome, timestamp)
spend_records (id, agent_id, amount_usd, tx_hash, timestamp)
revocations (id, agent_id, revoked_by, reason, revoked_at)
```

### Event Schema (The Graph Subgraph)

```graphql
type Agent @entity {
  id: ID!               # DID
  owner: Bytes!
  createdAt: BigInt!
  status: String!
  actions: [AuditEvent!]! @derivedFrom(field: "agent")
}

type AuditEvent @entity {
  id: ID!               # txHash-logIndex
  agent: Agent!
  actionType: String!
  txHash: Bytes!
  blockNumber: BigInt!
  timestamp: BigInt!
  outcome: String!
}
```

---

## 11. API Design

### SDK (TypeScript — Primary)

```typescript
import { AgentShield } from '@agentshield/sdk';

// Initialise
const shield = new AgentShield({
  chain: 'base',
  rpcUrl: process.env.RPC_URL,
  apiKey: process.env.AGENTSHIELD_API_KEY,
});

// Register a new agent
const agent = await shield.registerAgent({
  address: agentWallet.address,
  model: 'claude-sonnet-4-6',
  owner: enterpriseWallet.address,
});
// Returns: { did: 'did:ethr:base:0x...', agentId: '0x...' }

// Define permission scope
const scope = await shield.grantPermission(agent.agentId, {
  allowedProtocols: ['uniswap_v3', 'aave_v3'],
  dailySpendCapUSD: 2000,
  perTxSpendCapUSD: 500,
  allowedTokens: ['USDC', 'ETH', 'WBTC'],
  validUntil: Date.now() + 90 * 24 * 60 * 60 * 1000, // 90 days
});

// Wrap your existing agent execution
const wrappedAgent = shield.wrapAgent(yourLangChainAgent, {
  agentId: agent.agentId,
  enforceOnChain: true,
});

// Every action now goes through permission check
await wrappedAgent.execute("Swap 200 USDC for ETH on Uniswap");

// Revoke instantly
await shield.revokeAgent(agent.agentId, { reason: 'Suspicious activity' });

// Query audit trail
const actions = await shield.getAuditTrail(agent.agentId, {
  from: Date.now() - 7 * 24 * 60 * 60 * 1000, // last 7 days
  limit: 100,
});
```

### REST API (Enterprise Compliance)

```
POST   /v1/agents                    — Register new agent
GET    /v1/agents/{did}              — Resolve agent identity
POST   /v1/agents/{did}/permissions  — Grant permission scope
DELETE /v1/agents/{did}/permissions  — Revoke agent
GET    /v1/agents/{did}/audit        — Get audit trail
GET    /v1/agents/{did}/spend        — Get spend summary
POST   /v1/agents/{did}/revoke       — Emergency revoke
GET    /v1/compliance/report         — Export regulatory report
GET    /v1/agents                    — List all enterprise agents
```

### Webhooks (Real-Time Alerts)

```json
// Permission violation event
{
  "event": "permission.violation",
  "agentId": "did:ethr:base:0x...",
  "violation": "spend_cap_exceeded",
  "attempted": 600,
  "cap": 500,
  "tx_blocked": true,
  "timestamp": 1748000000
}

// Agent revoked event
{
  "event": "agent.revoked",
  "agentId": "did:ethr:base:0x...",
  "revokedBy": "0xOPERATOR",
  "reason": "Unusual trading pattern",
  "timestamp": 1748000000
}
```

---

## 12. 12-Month Technical Roadmap

### Phase 0 — Research & Foundations (Months 1–2)

**Goal:** Deep technical understanding + initial IP

- [ ] Comprehensive analysis of ERC-7579, ERC-4337, EIP-7702, EIP-5564
- [ ] Survey all existing agent frameworks (LangChain, ELIZA, GOAT, AgentKit) — map integration points
- [ ] Build toy implementation of permission scopes in Foundry — prove the concept works on-chain
- [ ] Write technical specification document (this becomes your MSc thesis proposal)
- [ ] Set up development environment, CI/CD pipeline
- [ ] Register GitHub org, publish preliminary spec as RFC

**Deliverable:** Technical spec + proof-of-concept smart contracts on Foundry testnet

---

### Phase 1 — Core Protocol MVP (Months 3–5)

**Goal:** Working protocol on testnet with basic SDK

- [ ] `AgentRegistry.sol` — deploy and test on Base Sepolia
- [ ] `PermissionVault.sol` — ERC-7579 module with basic scope types
- [ ] `SpendTracker.sol` — rolling window with Chainlink price feed
- [ ] `RevocationRegistry.sol` — instant revocation mechanism
- [ ] TypeScript SDK v0.1 — register, grant, revoke, check
- [ ] LangChain integration (most popular framework — biggest reach)
- [ ] Basic React dashboard — view agents, see permissions, trigger revoke
- [ ] Integration tests with a real Uniswap v3 swap on Base Sepolia

**Deliverable:** Open-source repo on GitHub, working testnet demo, developer docs

---

### Phase 2 — Developer Ecosystem (Months 6–7)

**Goal:** Get developers building on the protocol

- [ ] ELIZA Framework integration (Web3-native, fastest-growing)
- [ ] Coinbase AgentKit integration (huge ecosystem, direct access to their agent developers)
- [ ] Python SDK v0.1
- [ ] Subgraph deployment on The Graph for audit indexing
- [ ] Developer documentation site (docusaurus)
- [ ] Community launch: Twitter/X, Farcaster, Discord
- [ ] Submit EIP/ERC proposal for agent permission standard (establishes thought leadership)
- [ ] First 10 external developers using SDK (target via ETHGlobal hackathons)

**Deliverable:** Active developer community, SDK adoption metrics, formal EIP submission

---

### Phase 3 — Security & Audit Hardening (Month 8)

**Goal:** Make protocol safe enough for real money

- [ ] Echidna fuzz testing campaign — 10M+ iterations on PermissionVault
- [ ] Slither + Mythril full analysis + remediation
- [ ] Formal verification of critical paths (Certora Prover)
- [ ] Third-party security audit (at minimum a community audit via Code4rena — free)
- [ ] Immunefi bug bounty program launch
- [ ] Tenderly monitoring setup — alerts for any anomalous on-chain behaviour

**Deliverable:** Security audit report, bug bounty program, hardened contracts

---

### Phase 4 — Enterprise Pilot (Months 9–10)

**Goal:** One real enterprise running agents with AgentShield in production

- [ ] Package SaaS dashboard for enterprise use (auth, multi-user, audit export)
- [ ] MAS regulatory compliance report template (Singapore-specific)
- [ ] Target: 1 Singapore fintech or DeFi protocol running AI treasury agent
- [ ] Build compliance export: PDF report ready for MAS regulatory submission
- [ ] Multi-chain support: Base + Arbitrum + Ethereum mainnet
- [ ] SLA and incident response protocol

**Key lead sources:**
- NTU industry connections
- MAS FinTech Festival network (November each year)
- Coinbase developer ecosystem (AgentKit integration gives warm intro)

**Deliverable:** One live enterprise pilot with on-chain activity, testimonial, case study

---

### Phase 5 — Mainnet Launch & Seed Raise (Months 11–12)

**Goal:** Live on mainnet, begin revenue, close seed round

- [ ] Mainnet deployment on Base, Arbitrum, Ethereum
- [ ] Mainnet agent activity: target 50+ active registered agents
- [ ] SaaS pricing launched: Free tier (open-source) + Pro ($500/month) + Enterprise (custom)
- [ ] Seed deck with: on-chain traction, enterprise pilot, protocol adoption metrics
- [ ] Target investors: a16z crypto, Polychain, Multicoin, SEA-focused: Spartan Group, HashKey Capital
- [ ] Apply to a16z crypto startup school, Coinbase Ventures grants

**Deliverable:** Live mainnet product, first revenue, seed round in process

---

## 13. Business Model

### Revenue Streams

**Tier 1 — Open Source (Free)**
- Core protocol contracts (open-source forever)
- TypeScript + Python SDK
- Basic dashboard (1 user, up to 5 agents)
- Community support

*Strategy: Maximize adoption, become the standard*

---

**Tier 2 — Pro SaaS ($499/month per organisation)**
- Unlimited agents
- Full audit trail + 12-month retention
- Webhook alerts + Slack integration
- Compliance report export (MAS, MiCA format)
- Priority support
- Advanced anomaly detection

*Target: DeFi protocols, trading firms, crypto-native enterprises*

---

**Tier 3 — Enterprise (Custom, $5,000–50,000/month)**
- Private deployment option (dedicated infrastructure)
- Custom compliance report formats (per jurisdiction)
- SLA: 99.99% uptime, < 2s revocation guarantee
- Dedicated account manager
- Custom integration support
- Regulator portal access (read-only for auditors)

*Target: Singapore and HK banks, TradFi entering DeFi, large DAO treasuries*

---

**Tier 4 — Protocol Fees (On-Chain, Long-Term)**
- Small fee per permission grant transaction (e.g. $0.10 equivalent)
- Fee per audit record anchored on-chain
- This becomes the sustainable economic model if the standard achieves wide adoption

---

### Financial Projections (Conservative)

| Month | Active Orgs | MRR | Notes |
|---|---|---|---|
| 6 | 0 | $0 | Pre-launch, building |
| 9 | 3 | $1,500 | 3 beta pilots (discounted) |
| 12 | 12 | $6,000 | Mainnet launch |
| 18 | 45 | $28,000 | Post-seed growth |
| 24 | 120 | $85,000 | Series A territory |

---

## 14. Go-To-Market Strategy

### The Open Source Wedge

Release everything for free on GitHub. The goal in Year 1 is **standard adoption**, not revenue. Every developer who builds an agent using AgentShield's SDK:

1. Creates on-chain activity that validates the protocol
2. Becomes a reference customer for enterprise conversations
3. Propagates the AgentShield identity format, making it harder for a competitor to displace it

This is the exact playbook used by **HashiCorp** (Vault), **Stripe** (Stripe.js), and **OpenTelemetry**.

### Developer-First GTM

**Step 1:** Publish the ERC/EIP draft for agent permission standards. Write a detailed post on ethresearch.ch and Mirror.xyz. This generates credibility before you have a product.

**Step 2:** ETHGlobal hackathons — sponsor a $2,000 prize for "best AI agent security implementation". You get 20+ developers building integrations in a weekend.

**Step 3:** Direct integrations with LangChain, ELIZA, Coinbase AgentKit docs. When developers look up "how do I add permissions to my agent", AgentShield is the first result.

**Step 4:** Ship a weekly newsletter on AI × blockchain security incidents. You become the authoritative voice on the problem you're solving.

### Enterprise GTM (Singapore First)

The Singapore market is uniquely accessible for three reasons:
1. **Small, well-networked** — 10 introductions can reach most major players
2. **MAS regulatory sandbox** — co-develop with banks under regulatory protection
3. **NTU network** — your professors almost certainly have bank and fintech relationships

**Priority targets:**
- DBS Bank (largest SEA bank, active in DeFi)
- Grab Financial Group (fintech, crypto products)
- Matrixport, Amber Group (crypto-native firms with agent deployments)
- HashKey Exchange (licensed crypto exchange, compliance focus)
- Any DAO treasury with > $50M in assets

**Sales motion:** "Your AI agent is one configuration error away from draining your treasury. Here is a live demo of AgentShield stopping that in three seconds."

---

## 15. Competitive Landscape

### Direct Competitors (None Yet — This Is The Point)

There is no direct competitor building specifically what AgentShield builds. This is the whitespace.

### Adjacent Players (Partial Overlap)

| Company | What They Do | Why They're Not Us |
|---|---|---|
| **Safe (Gnosis Safe)** | Multisig wallets, Guard modules | Human multisig, not AI agent-specific; no permission scopes |
| **Coinbase AgentKit** | Wallet + tools for AI agents | Provides wallets — has no permission/auth layer; we complement them |
| **Lit Protocol** | Programmable key management | Key management only, not agent-specific permission scopes |
| **Privy** | Embedded wallets for apps | Consumer wallet infra, not enterprise agent governance |
| **EigenLayer** | Restaking + AVS network | Infrastructure layer; could use EigenLayer for our validation network |
| **Biconomy** | Account abstraction tooling | AA infra, not permission/audit layer |
| **Permissionless.js** | AA developer toolkit | Developer SDK, not a product or standard |
| **Fetch.ai** | Multi-agent systems | Builds agents, not the trust infrastructure for agents |

### Moat Analysis

| Moat Type | Description | Strength |
|---|---|---|
| Standard ownership | If AgentShield's DID format becomes the industry default | Very High (winner-take-most) |
| Audit data network effect | The more agents use it, the more useful the anomaly detection | High |
| Regulatory relationships | Being the preferred compliance layer for MAS-regulated firms | High |
| Developer mindshare | First integration in every major agent framework | Medium-High |
| Technical IP | ZK-based audit proofs, formal verification | Medium |

---

## 16. Team & Hiring Plan

### Founding Team (Ideal)

| Role | Background | Responsibility |
|---|---|---|
| **CEO / Protocol Lead** | You — MSc Blockchain NTU | Vision, protocol design, fundraising, enterprise sales |
| **Smart Contract Lead** | Solidity engineer, ERC-7579 experience | Core contracts, security |
| **AI/Agent Integration Lead** | LangChain / agent framework developer | SDK, agent integrations |
| **Full-Stack Engineer** | React + Node + The Graph | Dashboard, API, subgraph |

**Where to find co-founders:**
- NTU School of Computer Science and Engineering
- ETHGlobal hackathons (Singapore, Seoul, Bangkok)
- Farcaster's /dev and /ethereum channels
- Telegram: t.me/ETHSingapore community

### First 3 Hires (Post-Seed, ~Month 14)

1. **Senior Solidity Auditor** — own the security process
2. **Developer Relations Engineer** — grow the developer ecosystem
3. **Enterprise Sales / BD** — Singapore-based, financial services background

---

## 17. Funding Strategy

### Pre-Seed (Now → Month 12)

**Target:** $0 — bootstrap through:
- NTU research grant (apply immediately — MSc projects qualify)
- NTU Graduate Research Scholarship stipend
- Ethereum Foundation grants (apply for "AI × blockchain" category)
- a16z crypto startup school (free + $500k SAFE option)
- Coinbase Ventures developer grants

**Goal:** Reach mainnet with enterprise pilot before raising. This maximises your valuation and minimises dilution.

### Seed Round (Month 12–14)

**Target:** $2–4M at $12–18M valuation

**Use of funds:**
- 40% Engineering (2 additional smart contract / backend engineers)
- 25% Security (audit, bug bounty fund)
- 20% Go-to-market (DevRel, marketing)
- 15% Operations

**Target investors:**
| Investor | Why | Contact Approach |
|---|---|---|
| Polychain Capital | Deep protocol infra thesis | ETHGlobal → warm intro |
| a16z crypto | Web3 infrastructure focus | a16z crypto startup school |
| Spartan Group | Singapore-based, SEA focus | Local network |
| HashKey Capital | HK/Singapore, compliance focus | MAS FinTech Festival |
| Coinbase Ventures | AgentKit integration = natural fit | Direct via AgentKit team contact |
| Dragonfly Capital | Technical infrastructure | Cold outreach + EIP credibility |

---

## 18. Risk Analysis

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| ERC-7579 doesn't achieve wide adoption | Medium | High | Build adapter layer for ERC-6900, ERC-4337 directly |
| Gas costs make on-chain checks uneconomical | Medium | Medium | Hybrid approach: off-chain checks, on-chain anchoring only |
| ZK proofs too slow for real-time enforcement | High (for now) | Medium | Phase ZK features into roadmap after basic enforcement works |
| Major smart contract exploit | Low | Critical | Formal verification + multiple audits + bug bounty |

### Market Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Well-funded competitor enters (e.g. Safe, Coinbase) | Medium | High | Win by being first open standard; they'll integrate us, not kill us |
| AI agent adoption slows | Low | High | The problem exists even with fewer agents; any growth helps us |
| Regulatory overreach bans autonomous agents | Very Low | High | Regulatory clarity is more likely; compliance focus is the right bet |
| Enterprises self-build the solution | Low | Medium | Too complex + no standard incentive; they'll buy vs. build |

### Execution Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Can't find technical co-founder | Medium | Critical | Start at ETHGlobal; use NTU network |
| Enterprise sales cycle too slow | High | Medium | Start with developer community; enterprise revenue is Year 2 |
| Protocol fragmentation (multiple competing standards) | Medium | Medium | Publish EIP early; move fast on integrations |

---

## 19. MSc Thesis Angle

### How Your Thesis Becomes Your Startup

This is the single biggest structural advantage you have that a Silicon Valley entrepreneur doesn't — **1–2 years of funded research time** to build the intellectual foundation before you need revenue.

### Proposed Thesis Title

> **"Decentralised Permission Architectures for Autonomous AI Agents in Blockchain Environments: A Formal Model and Protocol Design"**

### Thesis Structure

**Chapter 1 — Introduction & Problem Statement**
- Quantitative analysis of the AI agent explosion (17k+ agents, value at risk)
- Formal definition of the "agent authorisation problem" in blockchain environments
- Threat modelling: what goes wrong without a permission layer

**Chapter 2 — Related Work**
- OAuth 2.0 and its limitations for autonomous systems
- Existing blockchain permission systems (Safe Guards, Access Control)
- Decentralised identity (DIDs, Verifiable Credentials)
- AI agent frameworks and their security models

**Chapter 3 — Formal Model**
- Formal grammar for permission scopes (this is the academic IP)
- Proof of completeness: which attack vectors the model covers
- Analysis of revocation semantics and liveness guarantees

**Chapter 4 — Protocol Design**
- AgentShield protocol specification
- Smart contract architecture
- Security proofs

**Chapter 5 — Implementation & Evaluation**
- Testnet deployment
- Gas cost analysis
- Comparison with naive approaches
- Case study: simulated DeFi agent attack, with and without AgentShield

**Chapter 6 — Conclusion & Future Work**
- Path to standards adoption
- ZK-enhanced audit proofs (future work)

### Why This Works as Both Thesis and Startup

The Chapter 3 formal model is pure academic contribution — it's novel, rigorous, and publishable in IEEE/ACM venues. The Chapter 4 protocol design is the startup's open-source core. The Chapter 5 evaluation is the proof-of-concept that becomes your testnet MVP.

Your thesis advisor reviews the academic work. Your GitHub repo builds the developer community. Both validate each other.

---

## 20. Appendix

### Key Standards to Study

| Standard | Link | Priority |
|---|---|---|
| ERC-7579 — Minimal Modular Smart Accounts | eips.ethereum.org/EIPS/eip-7579 | Critical |
| ERC-4337 — Account Abstraction | eips.ethereum.org/EIPS/eip-4337 | Critical |
| EIP-7702 — EOA as Smart Account | eips.ethereum.org/EIPS/eip-7702 | Critical |
| W3C DID Core | w3.org/TR/did-core | Critical |
| W3C Verifiable Credentials | w3.org/TR/vc-data-model | High |
| ERC-6900 — Modular Smart Accounts | eips.ethereum.org/EIPS/eip-6900 | High |
| EIP-5564 — Stealth Addresses | eips.ethereum.org/EIPS/eip-5564 | Medium |
| x402 Payment Protocol | x402.org | Medium |

### Key Communities to Join

- **ETHResearch** (ethresearch.ch) — post your EIP draft here
- **Ethereum Magicians** (ethereum-magicians.org) — standards discussion
- **ERC-7579 Telegram** — direct access to the standard authors
- **LangChain Discord** — agent developer community
- **Farcaster /build** — Web3 developer social graph
- **NTU Blockchain Club** — local talent pipeline

### Recommended Reading

- "Authenticating Autonomous Agents" — Ethereum Foundation blog (2025)
- "The Agent Economy" — Coinbase research report (2025)
- "Principles of Model Checking" — Baier & Katoen (formal verification foundations)
- "Programming Bitcoin" — Jimmy Song (Bitcoin Script + UTXO model mental model)
- "Mastering Ethereum" — Antonopoulos (foundational)

### First Week Action Items

1. **Day 1:** Fork the ERC-7579 reference implementation on GitHub. Read the full spec. Write notes on every gap you see for AI agents specifically.
2. **Day 2:** Install Foundry. Write a basic `PermissionVault.sol` that can store a permission scope and check one condition. Get it to compile.
3. **Day 3:** Install LangChain. Build a toy agent that makes a Uniswap call on a testnet. Then add a manual (non-smart-contract) permission check in front of it. Understand the integration point.
4. **Day 4:** Read all three of these: ERC-7579 spec, W3C DID Core spec, the Coinbase AgentKit docs. Map where the gaps are. Write 500 words describing the gap — this is the opening paragraph of your thesis.
5. **Day 5:** Post on Farcaster and Twitter: "Building an open-source permission standard for AI agents on blockchain. Documenting the journey. What are the biggest pain points you've seen with agents and on-chain security?" — start building in public from day one.

---

*Document version 1.0 — March 2026*  
*Built for NTU MSc Blockchain Student — Singapore*
