---
sidebar_position: 2
---

# AgentRegistry

`AgentRegistry.sol` is the identity layer. Every AI agent gets a W3C DID and a unique `agentId`.

**Address (Base Sepolia):** `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb`

---

## Key Concepts

- **`agentId`** — `keccak256(abi.encode(owner, agentWallet, nonce))` — deterministic, owner-scoped
- **DID** — `did:ethr:base:0x{agentWallet}` — W3C-compliant decentralised identifier
- **Hierarchy** — agents can have a `parentAgentId` for sub-agent delegation

## Write Functions

### `register`

```solidity
function register(
    address agentWallet,
    string calldata model,
    bytes32 parentAgentId,
    string calldata metadataCID
) external returns (bytes32 agentId)
```

Registers a new agent. Returns the unique `agentId`. Emits `AgentRegistered`.

| Param | Type | Description |
|---|---|---|
| `agentWallet` | `address` | The wallet address controlled by the agent |
| `model` | `string` | Model identifier (e.g. `"gpt-4o"`, `"claude-3-5"`) |
| `parentAgentId` | `bytes32` | Parent agent ID for hierarchy; `bytes32(0)` if top-level |
| `metadataCID` | `string` | IPFS CID of off-chain metadata (optional, can be `""`) |

### `updateStatus`

```solidity
function updateStatus(bytes32 agentId, AgentStatus newStatus) external
```

Updates agent status. Only the owner of the agent can call this.

### `setPermissionVault`

```solidity
function setPermissionVault(bytes32 agentId, address vault) external
```

Associates a PermissionVault with this agent. Only owner.

## Read Functions

### `resolve`

```solidity
function resolve(bytes32 agentId) external view returns (AgentRecord memory)
```

Returns the full `AgentRecord` struct for an agent.

### `getAgentId`

```solidity
function getAgentId(address agentWallet) external view returns (bytes32)
```

Reverse lookup: wallet address → agentId.

### `getAgentsByOwner`

```solidity
function getAgentsByOwner(address owner) external view returns (bytes32[] memory)
```

Returns all agentIds registered by a given owner.

### `isActive`

```solidity
function isActive(bytes32 agentId) external view returns (bool)
```

Returns `true` if the agent's status is `ACTIVE`.

## AgentRecord Struct

```solidity
struct AgentRecord {
    bytes32 agentId;
    address owner;
    address agentWallet;
    string did;             // "did:ethr:base:0x..."
    string model;
    bytes32 parentAgentId;
    string metadataCID;
    AgentStatus status;
    uint48 registeredAt;
    address permissionVault;
}
```

## Events

```solidity
event AgentRegistered(bytes32 indexed agentId, address indexed owner, address indexed agentWallet, string did, uint48 registeredAt);
event AgentStatusUpdated(bytes32 indexed agentId, AgentStatus newStatus);
```
