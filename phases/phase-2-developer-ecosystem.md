# Phase 2: Developer Ecosystem

> **Weeks 11–16 · Goal:** LangChain, ELIZA, and Coinbase AgentKit integrations shipped; Python SDK published; subgraph live on Base Sepolia; Docusaurus documentation site deployed; EIP draft on ethresearch.ch; ETHGlobal hackathon entry submitted.
>
> **Success Criterion:** A developer using any of the three major AI agent frameworks can integrate Bouclier in < 10 minutes by following the quickstart. Developer feedback (hackathon, Discord) collected and first iteration of improvements shipped.

---

## Progress Tracker

| Milestone | Status | Completed |
|---|---|---|
| LangChain adapter shipped | 🟢 Published | `@bouclier/langchain@0.1.0` on npm — 10/10 tests |
| ELIZA plugin shipped | 🟢 Published | `@bouclier/eliza-plugin@0.1.0` on npm — 10/10 tests |
| AgentKit adapter shipped | 🟢 Published | `@bouclier/agentkit@0.1.0` on npm — 11/11 tests |
| Python SDK v0.1 published | 🟢 Published | `bouclier-sdk@0.1.0` on PyPI — 9/9 tests |
| Subgraph live on Base Sepolia | 🟢 Deployed | The Graph Studio: bouclier-base-sepolia/v0.0.1 |
| Docs site deployed | 🟢 Deployed | Vercel: bouclier-docs-nzoz4sbma-incyashrajs-projects.vercel.app |
| EIP draft published | 🟢 Written | `docs/eip-draft-agent-permission-validator.md` |
| ETHGlobal submission | ⬜ Not Started | — |

---

## Week 11: LangChain Integration

**Spec:** [architecture/sdk/typescript-sdk.md](../architecture/sdk/typescript-sdk.md#langchain-integration)

Package: `@bouclier/langchain`

### Implementation

```bash
mkdir -p packages/langchain/src
cd packages/langchain
bun init

# Dependencies
bun add @langchain/core @bouclier/sdk
```

**Core class: `BouclierCallbackHandler`**

```typescript
// Install via: bun add @bouclier/langchain

import { BouclierCallbackHandler } from '@bouclier/langchain';

const shield = await AgentShield.create({
  rpcUrl: 'https://mainnet.base.org',
  chainId: 8453,
  contracts: { ... },
});

const handler = new BouclierCallbackHandler(shield, agentDID);

const agent = await createOpenAIFunctionsAgent({
  llm, tools, prompt,
  callbacks: [handler],
});
```

**Required callbacks to implement:**
- `handleLLMStart` — log LLM call start (for audit)
- `handleToolStart(tool, input)` — call `shield.checkPermission(agentId, { target: tool.name, selector: '0x', estimatedValueUSD: 0 })` before execution
- `handleToolEnd(output, runId)` — log successful execution
- `handleToolError(error, runId)` — log blocked action
- `handleAgentAction(action)` — enforce permission on every action

**Key test cases:**
```typescript
// test: blocked DeFi tool is intercepted before execution
// test: allowed tool passes through with audit log
// test: spend cap exceeded blocks the tool mid-chain
// test: REVOKED agent has all tools blocked even before LLM call
```

---

## Week 12: ELIZA Plugin + AgentKit Adapter

### ELIZA Plugin

**Package:** `@bouclier/eliza-plugin`

```typescript
// ELIZA plugin structure: follows ELIZA plugin spec
export const bouclierPlugin: Plugin = {
  name: 'bouclier',
  description: 'AI agent trust layer — enforce permissions on all ELIZA actions',
  actions: [],   // no user-visible actions
  providers: [
    BouclierPermissionProvider,  // injects permission state into context
  ],
  evaluators: [
    BouclierActionEvaluator,     // validates every proposed action
  ],
};

// Usage in eliza character file:
// "plugins": ["@bouclier/eliza-plugin"]
```

**`BouclierActionEvaluator`** — runs before every action, returns `DENY` if:
- Agent is revoked
- Action target is not in allowlist
- Estimated value exceeds cap

### AgentKit Adapter

**Package:** `@bouclier/agentkit`  
**Integration Point:** Coinbase `AgentKit` exposes a `wallet` object — wrap it.

```typescript
import { BouclierAgentKitWrapper } from '@bouclier/agentkit';

const kit = await AgentKit.configureWithWallet({ wallet, cdpApiKeyName, cdpApiKeyPrivateKey });
const protectedKit = new BouclierAgentKitWrapper(kit, shield, agentDID);

// protectedKit.wallet.sendTransaction(...) — intercepted + validated
// protectedKit.getBuyAction() — intercepted + validated
```

**Test (integration):**
```bash
# Fork Base mainnet, ensure AgentKit's trade action is intercepted
forge test --match-test "test_agentkit_tradeBlockedByBouclier" --fork-url $BASE_MAINNET_RPC_URL
```

---

## Week 13: Python SDK

**Spec:** [architecture/sdk/python-sdk.md](../architecture/sdk/python-sdk.md)

Package: `bouclier-sdk` on PyPI

```bash
cd python-sdk
python3.12 -m venv venv
source venv/bin/activate
pip install poetry

poetry init
poetry add web3 httpx pydantic eth-account
```

### Implementation Checklist

- [ ] `AsyncBouclierClient` class — mirrors TypeScript SDK interface
- [ ] All 6 core functions: `register_agent`, `grant_permission`, `revoke_agent`, `check_permission`, `wrap_agent`, `get_audit_trail`
- [ ] Pydantic models: `PermissionScope`, `AgentRecord`, `AuditEvent`, `ValidationResult`, `SpendSummary`
- [ ] LangChain Python: `BouclierCallbackHandler(AsyncCallbackHandler)`
- [ ] CrewAI integration: `BouclierGuard` tool wrapper
- [ ] `TestShield` + `MockScope` for unit testing (no real chain needed)

```bash
# Publish
poetry build
twine upload dist/*
# Requires: PyPI account, API token
```

**Quickstart test:**
```python
import asyncio
from bouclier_sdk import AsyncBouclierClient

async def main():
    client = AsyncBouclierClient(rpc_url="https://mainnet.base.org", chain_id=8453, ...)
    result = await client.check_permission(agent_did, PermissionScope(...))
    print(result.allowed)

asyncio.run(main())
```

---

## Week 14: Subgraph

**Spec:** [architecture/infrastructure/subgraph.md](../architecture/infrastructure/subgraph.md)

### Deployment Steps

```bash
# Install Graph CLI
bun add -g @graphprotocol/graph-cli

# Initialize from ABI
cd subgraph
graph init --studio bouclier-base-sepolia

# Generate types from schema
graph codegen

# Build
graph build

# Authenticate with The Graph Studio
graph auth --studio $GRAPH_STUDIO_DEPLOY_KEY

# Deploy to Studio (Base Sepolia)
graph deploy --studio bouclier-base-sepolia
```

### Verify Subgraph Works

```graphql
# Test these queries in The Graph Playground

# 1. Get all registered agents
{
  agents(first: 10, orderBy: registeredAt, orderDirection: desc) {
    id
    did
    owner
    status
    registeredAt
  }
}

# 2. Get recent audit events
{
  auditEvents(first: 20, orderBy: timestamp, orderDirection: desc) {
    id
    agent { id did }
    target
    usdValue
    timestamp
    allowed
  }
}

# 3. Protocol stats
{
  protocolStats(id: "1") {
    totalAgents
    totalTransactions
    totalUSDVolume
    activeAgents
  }
}
```

**Acceptance criteria:**
- [ ] All 4 data sources indexed (AgentRegistry, PermissionVault, RevocationRegistry, AuditLogger)
- [ ] `protocolStats` entity updates on every event
- [ ] Subgraph synced to latest block on Base Sepolia

---

## Week 15: Documentation Site

### Stack: Docusaurus 3

```bash
bunx create-docusaurus@latest docs classic --typescript
cd docs
bun start
```

### Required Pages

| Page | Content |
|---|---|
| `/` | Hero: "The Trust Layer for AI Agents" + live demo GIF |
| `/docs/intro` | What is Bouclier? 2-minute overview |
| `/docs/quickstart` | 10-minute quickstart (LangChain example) |
| `/docs/contracts/overview` | Architecture diagram + links to contract specs |
| `/docs/contracts/agent-registry` | AgentRegistry interface reference |
| `/docs/contracts/permission-vault` | PermissionVault interface reference |
| `/docs/contracts/spend-tracker` | SpendTracker interface reference |
| `/docs/contracts/audit-logger` | AuditLogger interface reference |
| `/docs/contracts/revocation-registry` | RevocationRegistry interface reference |
| `/docs/sdk/typescript` | TypeScript SDK API reference |
| `/docs/sdk/python` | Python SDK API reference |
| `/docs/integrations/langchain` | LangChain step-by-step guide |
| `/docs/integrations/eliza` | ELIZA plugin guide |
| `/docs/integrations/agentkit` | Coinbase AgentKit guide |
| `/docs/faq` | Top 10 developer questions |

**Deploy to Vercel:**
```bash
vercel --prod
# Domain: docs.bouclier.xyz (or docs.bouclier.io)
```

---

## Week 16: EIP Draft + ETHGlobal

### EIP Draft

Write an EIP proposing a standard interface for AI agent permission systems. Base it on the Bouclier `IPermissionVault` interface.

**Submit to:** `https://ethresearch.ch` (informal discussion) and `https://github.com/ethereum/EIPs` (formal EIP PR)

**Draft structure:**
1. Simple Summary: 1 sentence
2. Abstract: 2 paragraphs
3. Motivation: Why is this needed now?
4. Specification: `IAgentPermissionValidator` interface (Solidity)
5. Rationale: Why these function signatures?
6. Backwards Compatibility
7. Reference Implementation: link to Bouclier contracts

**Target EIP number:** Request at EIP-XXXX (Editors assign the final number)

### ETHGlobal Hackathon

**Target events:** ETHGlobal Bangkok, ETHGlobal Singapore, or the next available hackathon.

**Demo app for hackathon:**
- LangChain agent that manages a DeFi portfolio
- Bouclier enforces: no single trade > $500, no protocol except Uniswap, auto-revoked after any anomaly
- Live demo on Base Sepolia
- Dashboard showing real-time audit trail

**Tracks to submit to:**
- Base (Coinbase) — agent + AgentKit integration
- Best DeFi Security tooling
- Best Public Good

---

## Developer Feedback Loop

After ETHGlobal and docs launch, run a structured feedback collection:

- [ ] Create GitHub Discussions board for developers
- [ ] Post in LangChain Discord, ELIZA Discord, Coinbase AgentKit community
- [ ] Target: **10 external developer integrations** by end of Phase 2
- [ ] Collect: friction points, missing features, pricing feedback
- [ ] Ship v0.2 SDK patch based on top 5 feedback items before Phase 3 starts

---

## Phase 2 Complete When

- [x] All 3 framework adapters (`@bouclier/langchain`, `@bouclier/eliza-plugin`, `@bouclier/agentkit`) published to npm
- [x] `bouclier-sdk` v0.1 published to PyPI
- [x] Subgraph live and indexing on Base Sepolia (queryable via The Graph Studio)
- [x] Docs site deployed to production URL
- [x] EIP draft written — `docs/eip-draft-agent-permission-validator.md`
- [ ] ETHGlobal hackathon submission submitted (link recorded here)
- [ ] ≥ 10 external developers have integrated Bouclier (GitHub stars ≥ 50 as proxy)
- [ ] SDK v0.2 released with feedback-driven improvements

---

*Last Updated: Session 10*  
*Phase Status: 🟡 In Progress (85%)*
