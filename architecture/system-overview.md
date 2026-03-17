# Bouclier — System Architecture Overview

> This document is the canonical technical reference for the Bouclier system architecture. All implementation work must trace back to the design decisions recorded here.

---

## Full System Diagram

```
╔══════════════════════════════════════════════════════════════════════╗
║                       HUMAN / ENTERPRISE                             ║
║             (Creates agents, defines permission scopes)              ║
╚══════════════════════════╦═══════════════════════════════════════════╝
                           ║  Signed Permission Grant (EIP-712)
                           ║  via Compliance Dashboard or SDK
                           ▼
╔══════════════════════════════════════════════════════════════════════╗
║                     BOUCLIER PROTOCOL LAYER                          ║
║                                                                      ║
║  ┌──────────────────┐  ┌───────────────────┐  ┌──────────────────┐  ║
║  │  AgentRegistry   │  │  PermissionVault  │  │   AuditLogger    │  ║
║  │  (DID + metadata)│  │  (ERC-7579 module)│  │  (on-chain hash) │  ║
║  └────────┬─────────┘  └────────┬──────────┘  └────────┬─────────┘  ║
║           │                     │                       │            ║
║  ┌────────┴──────────────────────┴───────────────────────┴─────────┐ ║
║  │            RevocationRegistry     SpendTracker                  │ ║
║  └─────────────────────────────────────────────────────────────────┘ ║
╚══════════════════════════╦═══════════════════════════════════════════╝
                           ║  SDK intercepts every UserOp
                           ║  before broadcast to mempool
                           ▼
╔══════════════════════════════════════════════════════════════════════╗
║                         AI AGENT RUNTIME                             ║
║   (LangChain / ELIZA / Coinbase AgentKit / Custom agent)            ║
║   Agent constructs UserOp: "Swap 300 USDC → ETH on Uniswap"        ║
╚══════════════════════════╦═══════════════════════════════════════════╝
                           ║  UserOp sent to SDK wrapper
                           ▼
╔══════════════════════════════════════════════════════════════════════╗
║                 PERMISSION ENFORCEMENT LAYER                         ║
║                                                                      ║
║  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  ║
║  │  ScopeValidator  │  │ SpendRateLimiter  │  │ RevocationCheck  │  ║
║  │  (protocol +     │  │ (Chainlink USD    │  │ (on-chain flag   │  ║
║  │   selector +     │  │  rolling window)  │  │  + Redis cache)  │  ║
║  │   asset +        │  │                  │  │                  │  ║
║  │   time window)   │  │                  │  │                  │  ║
║  └──────────────────┘  └──────────────────┘  └──────────────────┘  ║
║                                  │                                   ║
║                        ALLOW / DENY + LOG                           ║
╚══════════════════════════╦═══════════════════════════════════════════╝
                           ║
              ┌────────────┴──────────────┐
              │ ALLOW                     │ DENY
              ▼                           ▼
╔══════════════════════╗     ╔═══════════════════════════════════════╗
║  BLOCKCHAIN          ║     ║  VIOLATION EVENT                      ║
║  SETTLEMENT          ║     ║  · Transaction reverted               ║
║                      ║     ║  · AuditLogger records violation      ║
║  Base / Arbitrum /   ║     ║  · Webhook fired: permission.violation║
║  Ethereum            ║     ║  · Dashboard alert shown              ║
╚══════════════════════╝     ╚═══════════════════════════════════════╝
         │
         ▼
╔══════════════════════════════════════════════════════════════════════╗
║                     AUDIT & INDEXING LAYER                           ║
║                                                                      ║
║  On-chain events     →  The Graph Subgraph  →  PostgreSQL (SaaS)   ║
║  IPFS (full records) →  Dashboard API       →  Compliance Reports   ║
╚══════════════════════════════════════════════════════════════════════╝
```

---

## Architectural Layers Detail

### Layer 1 — Identity Layer

**Purpose:** Assigns and resolves persistent, verifiable identities to AI agents.

**Standard:** W3C DID Core, using the `did:ethr` method  
**Agent DID format:** `did:ethr:base:0xAGENT_ADDRESS`

**Key components:**
- `AgentRegistry.sol` — stores DID ↔ address mapping on-chain
- DID document stored on IPFS (off-chain), hash anchored on-chain
- Supports DID resolution via standard W3C DID Resolver interface

**DID Document Structure:**
```json
{
  "@context": "https://www.w3.org/ns/did/v1",
  "id": "did:ethr:base:0x1234...abcd",
  "verificationMethod": [{
    "id": "did:ethr:base:0x1234...abcd#controller",
    "type": "EcdsaSecp256k1RecoveryMethod2020",
    "controller": "did:ethr:base:0x1234...abcd",
    "blockchainAccountId": "eip155:8453:0x1234...abcd"
  }],
  "authentication": ["did:ethr:base:0x1234...abcd#controller"],
  "service": [{
    "id": "did:ethr:base:0x1234...abcd#bouclier",
    "type": "BouclierPermissionVault",
    "serviceEndpoint": "0xPERMISSION_VAULT_ADDRESS"
  }]
}
```

---

### Layer 2 — Permission Layer

**Purpose:** Stores and enforces granular permission scopes for agent actions.

**Standard:** ERC-7579 (Modular Smart Accounts) — `PermissionVault` is a Validator Module

**8 Permission Scope Types:**

| # | Type | Example | Enforcement Logic |
|---|---|---|---|
| 1 | Protocol allowlist | `[uniswap_v3, aave_v3]` | Check `calldata.target` against list |
| 2 | Daily spend cap (rolling) | $500 USDC/day | Sliding window accumulator via Chainlink USD |
| 3 | Per-tx spend cap | $200 max per tx | Single-transaction value check |
| 4 | Asset whitelist | `[USDC, ETH, WBTC]` | Parse calldata for ERC-20 token addresses |
| 5 | Time window | Mon–Fri 09:00–18:00 UTC | `block.timestamp` range check |
| 6 | Callable functions | `[swap(), addLiquidity()]` | First 4 bytes of calldata = function selector |
| 7 | Chain scope | `Base only` | `block.chainid` validation |
| 8 | Destination whitelist | Specific addresses | Exact match on `userOp.callData.target` |

**Why sliding window (not fixed daily reset)?**  
A fixed reset at midnight UTC allows an adversary to spend close to the cap just before midnight and again immediately after, effectively doubling the effective cap. A sliding window (e.g. "no more than $500 in any 24-hour window") prevents this.

---

### Layer 3 — Enforcement Layer

**Purpose:** Validates every agent action before it is broadcast to the mempool.

**Standard:** ERC-4337 UserOperation validation pipeline

**Enforcement flow:**
```
Agent builds UserOp
        ↓
Bouclier SDK intercepts (client-side)
        ↓
PermissionVault.validateUserOp() called
        ↓
  1. Check: isRevoked(agentId)?         → if true: REVERT
  2. Check: isWithinScope(userOp)?      → if false: REVERT
  3. Check: checkSpendCap(agentId)?     → if false: REVERT
  4. Record: spendTracker.recordSpend()
  5. Record: auditLogger.logAction()
        ↓
SIG_VALIDATION_SUCCESS returned
        ↓
UserOp sent to bundler → included in block
```

**ERC-7579 interface implemented:**
```solidity
interface IValidator {
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external returns (uint256 validationData);

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4 magicValue);
}
```

---

### Layer 4 — Audit Layer

**Purpose:** Append-only, tamper-evident log of every agent action.

**Storage strategy:**

```
Full audit record (JSON) → stored on IPFS (permanent)
         ↓
IPFS CID + minimal metadata → stored on-chain in AuditLogger events
         ↓
Events indexed by The Graph subgraph
         ↓
PostgreSQL mirrors indexed data for fast API queries
         ↓
Compliance dashboard queries PostgreSQL
         ↓
Regulatory export: PDF or CSV generated from PostgreSQL
```

**Audit record schema:**
```json
{
  "event_id": "0xHASH",
  "agent_did": "did:ethr:base:0x...",
  "action_type": "swap",
  "input_params": {
    "token_in": "USDC",
    "token_out": "ETH",
    "amount_in": "300000000",
    "amount_out_min": "0"
  },
  "target_protocol": "uniswap_v3",
  "target_contract": "0xUNISWAP_ROUTER",
  "function_selector": "0x04e45aaf",
  "tx_hash": "0x...",
  "block_number": 12345678,
  "timestamp": 1748000000,
  "permission_scope_id": "scope_xyz",
  "outcome": "success",
  "gas_used": 142000,
  "usd_value": 300.00
}
```

---

### Layer 5 — Revocation Layer

**Purpose:** Cryptographically verifiable, instant kill switch for any agent.

**Two-tier revocation:**

```
SOFT REVOCATION (off-chain speed)
Human clicks "Revoke" on dashboard
         ↓
API call → Redis flag set immediately (< 100ms)
         ↓
All subsequent SDK permission checks read Redis first
         ↓
On-chain transaction broadcast in parallel
         ↓
On-chain revocation confirmed (< 15s on Base)

HARD REVOCATION (on-chain enforcement)
emergencyRevoke(agentId) called on-chain
         ↓
1. revoked[agentId] = true
2. Spend caps set to zero
3. Session keys burned
4. AgentRevoked event emitted
         ↓
Any pending UserOps in mempool: rejected by bundler
(PermissionVault.validateUserOp returns VALIDATION_FAILED)
```

**Latency target:** < 2 seconds from human click to agent being unable to execute any transaction.

---

### Layer 6 — Compliance Layer

**Purpose:** Human-readable dashboard for enterprises and regulators. Does not touch the critical execution path — reads only.

**Components:**
- Next.js 15 web app hosted on Vercel
- Queries: PostgreSQL (primary), The Graph subgraph (real-time events), on-chain via RPC (live state)
- Authentication: Privy (supports wallet login + email)
- Multi-org: each enterprise has isolated data namespace
- Export: PDF compliance reports (jspdf), CSV audit trails

---

### Layer 7 — SDK Layer

**Purpose:** Developer tooling that abstracts all contract interactions into clean TypeScript/Python APIs.

**Key design principle:** `wrapAgent()` — developers do NOT need to rewrite their existing agents. They wrap them:

```typescript
// Before: unprotected agent
const result = await myLangChainAgent.run("Swap 300 USDC for ETH");

// After: one-line protection
const protected = shield.wrapAgent(myLangChainAgent, { agentId });
const result = await protected.run("Swap 300 USDC for ETH");
// ^ Every action now goes through Bouclier permission checks
```

SDK packages:
- `@bouclier/sdk` — core TypeScript SDK
- `@bouclier/langchain` — LangChain integration
- `@bouclier/eliza-plugin` — ELIZA framework plugin
- `@bouclier/agentkit` — Coinbase AgentKit extension
- `bouclier-sdk` — Python SDK (PyPI)

---

## Contract Dependency Graph

```
RevocationRegistry.sol (no dependencies)
           ↑
     used by: PermissionVault
           
AgentRegistry.sol (no dependencies)
           ↑
     used by: PermissionVault, AuditLogger

SpendTracker.sol
  └── depends on: Chainlink Price Feed Oracle
           ↑
     used by: PermissionVault

AuditLogger.sol
  └── depends on: AgentRegistry (for DID validation)
           ↑
     used by: PermissionVault

PermissionVault.sol  ← CORE CONTRACT
  └── depends on: RevocationRegistry
  └── depends on: SpendTracker
  └── depends on: AuditLogger
  └── implements: ERC-7579 IValidator
  └── implements: ERC-4337 IPaymaster (optional future)
```

**Implementation order (respects dependencies):**
1. `RevocationRegistry.sol`
2. `AgentRegistry.sol`
3. `SpendTracker.sol`
4. `AuditLogger.sol`
5. `PermissionVault.sol`

---

## Chain Deployment Strategy

| Chain | Role | Contracts Deployed | Rationale |
|---|---|---|---|
| **Base Sepolia** | Testnet (primary) | All 5 contracts | Coinbase ecosystem, low gas, AgentKit integration |
| **Base mainnet** | Production (primary) | All 5 contracts | Phase 4+ |
| **Arbitrum One** | Production (secondary) | All 5 contracts | DeFi ecosystem, Uniswap/Aave depth |
| **Ethereum mainnet** | Identity anchor | AgentRegistry + RevocationRegistry only | High-value identity records, legacy DeFi interop |

Cross-chain note: Permission scopes are per-chain. An agent with a Base permission scope cannot act on Arbitrum unless a separate scope is granted.

---

## Security Design Principles

1. **Minimal on-chain footprint** — only enforcement-critical data lives on-chain. Everything else is IPFS + PostgreSQL.
2. **No single admin key** — all admin operations go through a timelocked 3-of-5 Gnosis Safe multisig.
3. **Defence in depth** — SDK-level check + on-chain check (belt AND suspenders). Both must pass.
4. **Blast radius limiting** — even if an agent's key is compromised, it can only spend within its capped scope.
5. **Revocation first** — every path that touches agent execution checks revocation status before anything else.
6. **Deep calldata validation** — function selector check is NOT enough. Full calldata parsing prevents encoding attacks.

---

## Key Design Decisions (Rationale Recorded)

| Decision | Chosen Approach | Alternative | Why |
|---|---|---|---|
| Smart account standard | ERC-7579 (primary) + ERC-6900 (adapter) | Custom solution | ERC-7579 is widely adopted; we ride existing account infra |
| Spend denominator | USD via Chainlink oracle | Native token | USD caps are human-readable and business-meaningful |
| Spend window | Sliding 24h rolling window | Fixed midnight UTC reset | Fixed reset can be gamed (spend cap×2 around reset) |
| Revocation cache | Redis in front of on-chain flag | On-chain only | Sub-second revocation; on-chain is ground truth |
| Audit storage | IPFS hash on-chain, full record off-chain | Full on-chain | Gas cost of full records on-chain is prohibitive |
| SDK pattern | `wrapAgent()` wrapper | Requires agent rewrite | Zero friction for existing developers |
| DID method | `did:ethr` | `did:web`, `did:key` | Ethereum-native, no external DNS dependency, fully on-chain |
| Build tool | Foundry | Hardhat | Faster compilation, native fuzzing, Rust-based |

---

## References

| Standard | Description | Status |
|---|---|---|
| [ERC-7579](https://eips.ethereum.org/EIPS/eip-7579) | Minimal Modular Smart Accounts | Final |
| [ERC-4337](https://eips.ethereum.org/EIPS/eip-4337) | Account Abstraction via Entry Point | Final |
| [EIP-7702](https://eips.ethereum.org/EIPS/eip-7702) | Set EOA account code | Active |
| [ERC-6900](https://eips.ethereum.org/EIPS/eip-6900) | Modular Smart Contract Accounts | Draft |
| [W3C DID Core](https://www.w3.org/TR/did-core/) | Decentralised Identifiers | W3C Recommendation |
| [W3C VC Data Model](https://www.w3.org/TR/vc-data-model/) | Verifiable Credentials | W3C Recommendation |
| [EIP-712](https://eips.ethereum.org/EIPS/eip-712) | Typed structured data hashing/signing | Final |
| [EIP-5564](https://eips.ethereum.org/EIPS/eip-5564) | Stealth Addresses | Draft |

---

*Architecture Version 1.0 — March 2026*  
*Update this document when any design decision changes.*
