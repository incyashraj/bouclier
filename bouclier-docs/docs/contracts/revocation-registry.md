---
sidebar_position: 6
---

# RevocationRegistry

`RevocationRegistry.sol` is the kill switch. It allows authorised parties to instantly revoke an agent, with a 24-hour timelock on reinstatement (bypassable by `GUARDIAN_ROLE` for emergencies).

**Address (Base Sepolia):** `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa`

---

## Write Functions

### `revoke`

```solidity
function revoke(
    bytes32 agentId,
    uint8   level,
    string calldata notes
) external
```

Revokes an agent. Requires `REVOKER_ROLE` or owner. Emits `AgentRevoked`.

| Level | Meaning |
|---|---|
| `0` | Soft suspension (human review needed) |
| `1` | Security incident |
| `2` | Permanent ban |

### `batchRevoke`

```solidity
function batchRevoke(bytes32[] calldata agentIds, uint8 level, string calldata notes) external
```

Revokes multiple agents atomically. Requires `GUARDIAN_ROLE`.

### `reinstate`

```solidity
function reinstate(bytes32 agentId, string calldata notes) external
```

Reinstates a revoked agent. Enforces a **24-hour minimum timelock** from the time of revocation. `GUARDIAN_ROLE` can bypass this timelock in emergencies.

## Read Functions

### `isRevoked`

```solidity
function isRevoked(bytes32 agentId) external view returns (bool)
```

**Gas target: ≤ 2,200 gas** (single SLOAD). Called on every `validateUserOp` execution — must be cheap.

### `getRevocationRecord`

```solidity
function getRevocationRecord(bytes32 agentId) external view returns (RevocationRecord memory)
```

## RevocationRecord Struct

```solidity
struct RevocationRecord {
    bool    revoked;
    uint8   level;
    uint48  revokedAt;
    uint48  reinstatedAt;
    string  notes;
}
```

## Roles

| Role | Capability |
|---|---|
| `REVOKER_ROLE` | Can revoke individual agents |
| `GUARDIAN_ROLE` | Can batch-revoke and bypass reinstatement timelock |
| `DEFAULT_ADMIN_ROLE` | Can grant/revoke roles |

## Events

```solidity
event AgentRevoked(bytes32 indexed agentId, address indexed revokedBy, uint8 level, uint48 revokedAt);
event AgentReinstated(bytes32 indexed agentId, address indexed reinstatedBy, uint48 reinstatedAt);
```
