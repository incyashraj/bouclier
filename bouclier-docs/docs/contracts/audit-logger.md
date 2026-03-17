---
sidebar_position: 5
---

# AuditLogger

`AuditLogger.sol` is the append-only on-chain audit trail. Every action an agent takes is hashed and emitted as an event, with optional IPFS CID anchoring for full off-chain data.

**Address (Base Sepolia):** `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735`

---

## Design Principles

- **Append-only invariant** — records are NEVER modified after creation (Echidna-tested)
- **Paginated history** — `getAgentHistory(agentId, offset, limit)` for UI consumption
- **IPFS anchoring** — a backend service can add a CID to any record after the fact via `addIPFSCID`
- **Only PermissionVault** can call `logAction` — enforced by `LOGGER_ROLE`

## Write Functions

### `logAction`

```solidity
function logAction(
    bytes32 agentId,
    bytes32 actionHash,
    address target,
    bytes4  selector,
    address tokenAddress,
    uint256 usdAmount
) external returns (bytes32 eventId)
```

Logs a new action. **Only callable by addresses with `LOGGER_ROLE` (i.e. PermissionVault).**

Returns `eventId = keccak256(abi.encode(agentId, actionHash, block.number, logIndex))`.

### `addIPFSCID`

```solidity
function addIPFSCID(bytes32 eventId, string calldata cid) external
```

Attaches an IPFS CID to an existing record. Only callable by addresses with `IPFS_ROLE`.

## Read Functions

### `getAuditRecord`

```solidity
function getAuditRecord(bytes32 eventId) external view returns (AuditRecord memory)
```

### `getAgentHistory`

```solidity
function getAgentHistory(
    bytes32 agentId,
    uint256 offset,
    uint256 limit
) external view returns (bytes32[] memory eventIds)
```

### `getTotalEvents`

```solidity
function getTotalEvents(bytes32 agentId) external view returns (uint256)
```

## AuditRecord Struct

```solidity
struct AuditRecord {
    bytes32 agentId;
    bytes32 actionHash;
    address target;
    bytes4  selector;
    address tokenAddress;
    uint256 usdAmount;
    uint256 blockNumber;
    uint256 timestamp;
    string  ipfsCID;      // "" until addIPFSCID is called
}
```

## Events

```solidity
event ActionLogged(
    bytes32 indexed agentId,
    bytes32 indexed eventId,
    address indexed target,
    bytes4  selector,
    bool    allowed,
    uint48  timestamp
);
```
