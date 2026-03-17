# The Graph Subgraph — Architecture & Schema

> **Network:** The Graph Protocol (Subgraph Studio)  
> **Primary Subgraph:** Base mainnet / Base Sepolia  
> **Secondary:** Arbitrum One, Ethereum mainnet  
> **Query URL:** `https://api.studio.thegraph.com/query/[id]/bouclier/v0.1`

---

## Purpose

The Graph subgraph indexes all Bouclier smart contract events in real-time, making them queryable via GraphQL. The dashboard relies on the subgraph for:

- Agent activity feeds (last N events)
- Spend analytics (aggregate queries)
- Permission history (scope grants + revocations)
- Violation monitoring (all PermissionViolation events)

Without the subgraph, the dashboard would need to make individual RPC calls for every piece of data — prohibitively slow and expensive.

---

## GraphQL Schema

```graphql
# schema.graphql

# ─────────────────────────────────────────────────────────────────────
# AGENT ENTITIES
# ─────────────────────────────────────────────────────────────────────

type Agent @entity {
  id: ID!                              # DID (e.g. "did:ethr:base:0x...")
  agentId: Bytes!                      # bytes32 agentId
  agentAddress: Bytes!                 # Wallet address
  owner: Bytes!                        # Owner address
  model: String!
  status: String!                      # "active" | "suspended" | "revoked"
  permissionVault: Bytes               # PermissionVault contract address
  createdAt: BigInt!
  updatedAt: BigInt!
  
  # Derived relations
  auditEvents:    [AuditEvent!]!       @derivedFrom(field: "agent")
  scopes:         [PermissionScope!]!  @derivedFrom(field: "agent")
  spendRecords:   [SpendRecord!]!      @derivedFrom(field: "agent")
  revocations:    [RevocationEvent!]!  @derivedFrom(field: "agent")
  
  # Aggregated (computed in mappings)
  totalActions:    BigInt!             # Total validated action count
  totalViolations: BigInt!             # Total blocked action count
  totalSpentUSD:   BigDecimal!         # Lifetime USD spent (18-decimal precision)
}

# ─────────────────────────────────────────────────────────────────────
# PERMISSION SCOPES
# ─────────────────────────────────────────────────────────────────────

type PermissionScope @entity {
  id: ID!                              # scopeId (bytes32 hex)
  agent: Agent!
  grantedBy: Bytes!
  dailySpendCapUSD: BigDecimal!
  perTxSpendCapUSD: BigDecimal!
  validFrom: BigInt!
  validUntil: BigInt!                  # 0 = no expiry
  revoked: Boolean!
  revokedAt: BigInt
  grantHash: Bytes!
  createdAt: BigInt!
  
  # Derived
  actions: [AuditEvent!]! @derivedFrom(field: "permissionScope")
}

# ─────────────────────────────────────────────────────────────────────
# AUDIT EVENTS
# ─────────────────────────────────────────────────────────────────────

type AuditEvent @entity {
  id: ID!                              # eventId (bytes32 hex)
  agent: Agent!
  permissionScope: PermissionScope
  userOpHash: Bytes!
  targetContract: Bytes!
  functionSelector: Bytes!
  valueUSD: BigDecimal!
  outcome: String!                     # "success" | "violation"
  violationType: String                # Null if success
  ipfsCid: String                      # Empty until CID added
  blockNumber: BigInt!
  timestamp: BigInt!
  txHash: Bytes                        # Null for violations (no on-chain tx)
}

# ─────────────────────────────────────────────────────────────────────
# SPEND RECORDS
# ─────────────────────────────────────────────────────────────────────

type SpendRecord @entity {
  id: ID!                              # txHash-logIndex
  agent: Agent!
  amountUSD: BigDecimal!
  blockNumber: BigInt!
  timestamp: BigInt!
  txHash: Bytes!
}

# ─────────────────────────────────────────────────────────────────────
# REVOCATIONS
# ─────────────────────────────────────────────────────────────────────

type RevocationEvent @entity {
  id: ID!                              # agentId-blockNumber
  agent: Agent!
  revokedBy: Bytes!
  reason: String!
  customReason: String
  blockNumber: BigInt!
  timestamp: BigInt!
  txHash: Bytes!
  reinstated: Boolean!
  reinstatedAt: BigInt
  reinstatedBy: Bytes
}

# ─────────────────────────────────────────────────────────────────────
# PROTOCOL STATISTICS (Global)
# ─────────────────────────────────────────────────────────────────────

type ProtocolStats @entity {
  id: ID!                              # "global"
  totalAgents: BigInt!
  totalActiveAgents: BigInt!
  totalRevokedAgents: BigInt!
  totalActions: BigInt!
  totalViolations: BigInt!
  totalUSDProtected: BigDecimal!       # Lifetime USD processed by Bouclier
  lastUpdatedBlock: BigInt!
  lastUpdatedAt: BigInt!
}
```

---

## Event Handlers (subgraph.yaml mappings)

```yaml
# subgraph.yaml

specVersion: 0.0.5
schema:
  file: ./schema.graphql

dataSources:
  # ─── AgentRegistry ───────────────────────────────────────────────
  - kind: ethereum
    name: AgentRegistry
    network: base-sepolia             # will be 'base' for mainnet
    source:
      address: "0xAGENT_REGISTRY_ADDRESS"
      abi: AgentRegistry
      startBlock: 0
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Agent
        - ProtocolStats
      abis:
        - name: AgentRegistry
          file: ./abis/AgentRegistry.json
      eventHandlers:
        - event: AgentRegistered(indexed bytes32,indexed address,indexed address,string,uint48)
          handler: handleAgentRegistered
        - event: AgentStatusUpdated(indexed bytes32,uint8,uint8,address,uint48)
          handler: handleAgentStatusUpdated
      file: ./src/agent-registry.ts

  # ─── PermissionVault ─────────────────────────────────────────────
  - kind: ethereum
    name: PermissionVault
    network: base-sepolia
    source:
      address: "0xPERMISSION_VAULT_ADDRESS"
      abi: PermissionVault
      startBlock: 0
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - PermissionScope
        - AuditEvent
        - Agent
        - ProtocolStats
      abis:
        - name: PermissionVault
          file: ./abis/PermissionVault.json
      eventHandlers:
        - event: PermissionGranted(indexed bytes32,indexed bytes32,indexed address,uint48,uint48)
          handler: handlePermissionGranted
        - event: PermissionRevoked(indexed bytes32,indexed bytes32,indexed address,uint48)
          handler: handlePermissionRevoked
        - event: PermissionViolation(indexed bytes32,indexed address,bytes4,string,uint48)
          handler: handlePermissionViolation
        - event: ActionValidated(indexed bytes32,indexed bytes32,uint256,uint48)
          handler: handleActionValidated
      file: ./src/permission-vault.ts

  # ─── RevocationRegistry ──────────────────────────────────────────
  - kind: ethereum
    name: RevocationRegistry
    network: base-sepolia
    source:
      address: "0xREVOCATION_REGISTRY_ADDRESS"
      abi: RevocationRegistry
      startBlock: 0
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - Agent
        - RevocationEvent
        - ProtocolStats
      abis:
        - name: RevocationRegistry
          file: ./abis/RevocationRegistry.json
      eventHandlers:
        - event: AgentRevoked(indexed bytes32,indexed address,uint8,string,uint48,uint64)
          handler: handleAgentRevoked
        - event: AgentReinstated(indexed bytes32,indexed address,string,uint48)
          handler: handleAgentReinstated
      file: ./src/revocation-registry.ts

  # ─── AuditLogger ─────────────────────────────────────────────────
  - kind: ethereum
    name: AuditLogger
    network: base-sepolia
    source:
      address: "0xAUDIT_LOGGER_ADDRESS"
      abi: AuditLogger
      startBlock: 0
    mapping:
      kind: ethereum/events
      apiVersion: 0.0.7
      language: wasm/assemblyscript
      entities:
        - AuditEvent
        - Agent
      abis:
        - name: AuditLogger
          file: ./abis/AuditLogger.json
      eventHandlers:
        - event: ActionLogged(indexed bytes32,indexed bytes32,indexed bytes32,uint8,uint256,string,uint64,uint48)
          handler: handleActionLogged
        - event: AuditCidAdded(indexed bytes32,string,uint48)
          handler: handleAuditCidAdded
        - event: RevocationLogged(indexed bytes32,indexed address,string,uint48)
          handler: handleRevocationLogged
      file: ./src/audit-logger.ts
```

---

## Mapping Implementation (AssemblyScript)

```typescript
// src/agent-registry.ts

import { AgentRegistered, AgentStatusUpdated } from '../generated/AgentRegistry/AgentRegistry';
import { Agent, ProtocolStats } from '../generated/schema';
import { BigInt, BigDecimal } from '@graphprotocol/graph-ts';

export function handleAgentRegistered(event: AgentRegistered): void {
  let agent = new Agent(event.params.did);
  
  agent.agentId     = event.params.agentId;
  agent.agentAddress = event.params.agentAddress;
  agent.owner       = event.params.owner;
  agent.model       = "";  // Will be enriched by metadata update events
  agent.status      = "active";
  agent.createdAt   = event.params.timestamp;
  agent.updatedAt   = event.params.timestamp;
  agent.totalActions    = BigInt.fromI32(0);
  agent.totalViolations = BigInt.fromI32(0);
  agent.totalSpentUSD   = BigDecimal.fromString("0");
  
  agent.save();
  
  // Update global stats
  let stats = ProtocolStats.load("global");
  if (stats == null) {
    stats = new ProtocolStats("global");
    stats.totalAgents = BigInt.fromI32(0);
    stats.totalActiveAgents = BigInt.fromI32(0);
    stats.totalRevokedAgents = BigInt.fromI32(0);
    stats.totalActions = BigInt.fromI32(0);
    stats.totalViolations = BigInt.fromI32(0);
    stats.totalUSDProtected = BigDecimal.fromString("0");
  }
  
  stats.totalAgents = stats.totalAgents.plus(BigInt.fromI32(1));
  stats.totalActiveAgents = stats.totalActiveAgents.plus(BigInt.fromI32(1));
  stats.lastUpdatedBlock = event.block.number;
  stats.lastUpdatedAt = BigInt.fromI32(event.block.timestamp.toI32());
  stats.save();
}

export function handleAgentStatusUpdated(event: AgentStatusUpdated): void {
  // Note: AgentRegistry uses bytes32 agentId, but our GraphQL entity uses DID as ID
  // We need a secondary lookup: agentId → DID
  // This is handled by maintaining an index: AgentIdToDidIndex @entity
  // ...implementation details
}
```

---

## Key Queries (Dashboard Examples)

### Agent Dashboard — Recent Activity

```graphql
query AgentActivity($agentId: String!, $limit: Int!) {
  agent(id: $agentId) {
    id
    status
    totalActions
    totalViolations
    totalSpentUSD
    auditEvents(
      first: $limit,
      orderBy: timestamp,
      orderDirection: desc
    ) {
      id
      outcome
      violationType
      valueUSD
      targetContract
      functionSelector
      timestamp
      txHash
    }
  }
}
```

### Spend Analytics — Daily Breakdown

```graphql
query SpendBreakdown($agentId: String!, $since: BigInt!) {
  spendRecords(
    where: {
      agent: $agentId,
      timestamp_gte: $since
    }
    orderBy: timestamp
    orderDirection: asc
  ) {
    amountUSD
    timestamp
    txHash
  }
}
```

### Protocol-Wide Stats

```graphql
query ProtocolOverview {
  protocolStats(id: "global") {
    totalAgents
    totalActiveAgents
    totalRevokedAgents
    totalActions
    totalViolations
    totalUSDProtected
    lastUpdatedAt
  }
}
```

### Violation Monitor (Compliance Alert Feed)

```graphql
query RecentViolations($since: BigInt!) {
  auditEvents(
    where: {
      outcome: "violation",
      timestamp_gte: $since
    }
    orderBy: timestamp
    orderDirection: desc
    first: 50
  ) {
    id
    agent { id status }
    violationType
    valueUSD
    targetContract
    timestamp
  }
}
```

---

## Deployment Instructions

```bash
# Prerequisites
npm install -g @graphprotocol/graph-cli

# Initialise subgraph project
graph init --from-contract 0xAGENT_REGISTRY_ADDRESS \
           --network base-sepolia \
           --contract-name AgentRegistry \
           --abi ./abis/AgentRegistry.json

# Authenticate
graph auth --studio $GRAPH_STUDIO_DEPLOY_KEY

# Build
graph build

# Deploy to Subgraph Studio (testnet)
graph deploy --studio bouclier-testnet

# Deploy to The Graph Network (mainnet — requires GRT)
graph deploy --network base bouclier
```

**Subgraph IDs (to be filled after deployment):**
| Network | Subgraph ID | Status |
|---|---|---|
| Base Sepolia | TBD | Not deployed |
| Base mainnet | TBD | Not deployed |
| Arbitrum One | TBD | Not deployed |

---

*Last Updated: March 2026*
