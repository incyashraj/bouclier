# AuditLogger.sol — Contract Architecture

> **Contract:** `AuditLogger.sol`  
> **Layer:** Audit Layer  
> **Dependencies:** `AgentRegistry.sol` (for DID resolution)  
> **Used by:** `PermissionVault.sol`, The Graph subgraph, Compliance Dashboard

---

## Purpose

`AuditLogger` is the **append-only, tamper-evident audit trail** for all agent actions. It records a minimal on-chain footprint (hash + CID + metadata) for every action that passes permission validation — and for every violation that is blocked.

The full audit record is stored on IPFS; the on-chain log only anchors the IPFS hash (CID), providing immutability without prohibitive gas costs.

**Key properties:**
- **Append-only:** no log entry can ever be modified or deleted
- **Tamper-evident:** the IPFS CID is a content hash — any modification changes the CID
- **Complete:** every validated action AND every violation attempt is logged
- **Queryable:** The Graph indexes all events for fast dashboard queries
- **Compliant:** records contain all fields required by MAS and MiCA guidelines

---

## Full Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAuditLogger {

    // ─────────────────────────────────────────────────────────────────
    // STRUCTS
    // ─────────────────────────────────────────────────────────────────

    enum ActionOutcome {
        Success,           // Action executed successfully
        Violated,          // Action blocked by permission check
        Reverted           // Action was executed but the target contract reverted
    }

    struct AuditRecord {
        bytes32       eventId;          // keccak256(agentId, userOpHash, timestamp) 
        bytes32       agentId;          // The acting agent
        bytes32       userOpHash;       // ERC-4337 UserOp hash (links to tx)
        bytes32       txHash;           // Confirmed transaction hash (set async)
        bytes4        functionSelector; // First 4 bytes of calldata
        address       targetContract;  // Contract the agent called
        uint256       valueUSD;         // USD value of the action
        ActionOutcome outcome;
        string        violationType;   // Empty if outcome == Success
        string        ipfsCid;         // IPFS CID of full audit record JSON
        uint64        blockNumber;
        uint48        timestamp;
        bytes32       permissionScopeId;
    }

    // ─────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Emitted for every agent action (success or violation)
     * @dev Indexed fields enable efficient subgraph filtering
     */
    event ActionLogged(
        bytes32 indexed agentId,
        bytes32 indexed userOpHash,
        bytes32 indexed permissionScopeId,
        ActionOutcome   outcome,
        uint256         valueUSD,
        string          ipfsCid,       // "" initially, updated by logActionWithCid()
        uint64          blockNumber,
        uint48          timestamp
    );

    /**
     * @notice Emitted when the IPFS CID is added to an existing log entry
     * @dev The off-chain indexer calls logActionWithCid() after IPFS upload completes
     */
    event AuditCidAdded(
        bytes32 indexed eventId,
        string          ipfsCid,
        uint48          timestamp
    );

    /**
     * @notice Emitted when an agent is revoked — creates a permanent audit entry
     */
    event RevocationLogged(
        bytes32 indexed agentId,
        address indexed revokedBy,
        string          reason,
        uint48          timestamp
    );

    // ─────────────────────────────────────────────────────────────────
    // WRITE FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Logs an agent action (called by PermissionVault after successful validation)
     * @dev ONLY callable by PermissionVault (access-controlled)
     *      The IPFS CID is initially empty — updated later via logActionWithCid()
     *      This design keeps the hot path cheap (no IPFS upload in the critical path)
     * @param agentId           The agent that took the action
     * @param userOpHash        The ERC-4337 UserOp hash
     * @param targetContract    Contract the agent called
     * @param selector          Function selector called
     * @param valueUSD          USD value of the action (18 decimals)
     * @param permissionScopeId The scope under which this action was validated
     * @return eventId          Unique identifier for this audit entry
     */
    function logAction(
        bytes32 agentId,
        bytes32 userOpHash,
        address targetContract,
        bytes4  selector,
        uint256 valueUSD,
        bytes32 permissionScopeId
    ) external returns (bytes32 eventId);

    /**
     * @notice Logs a permission violation attempt (called by PermissionVault on rejection)
     * @dev ONLY callable by PermissionVault.
     *      Violations are logged even though no on-chain action was taken.
     *      Critical for compliance — regulators need to see blocked attempts too.
     * @param agentId        The agent that attempted the action
     * @param userOpHash     The UserOp hash
     * @param targetContract Target that was attempted
     * @param selector       Function selector attempted
     * @param valueUSD       Value that was attempted
     * @param violationType  e.g. "PROTOCOL_NOT_ALLOWED", "DAILY_CAP_EXCEEDED"
     */
    function logViolation(
        bytes32 agentId,
        bytes32 userOpHash,
        address targetContract,
        bytes4  selector,
        uint256 valueUSD,
        string  calldata violationType
    ) external;

    /**
     * @notice Adds an IPFS CID to an existing audit log entry
     * @dev Called by off-chain indexer after IPFS upload completes (async)
     *      ONLY callable by: PermissionVault OR authorised off-chain relayer
     * @param eventId  The audit entry to update
     * @param ipfsCid  IPFS content identifier of the full audit record JSON
     */
    function logActionWithCid(
        bytes32 eventId,
        string calldata ipfsCid
    ) external;

    /**
     * @notice Logs agent revocation event (called by RevocationRegistry)
     * @param agentId    The revoked agent
     * @param revokedBy  Who triggered the revocation
     * @param reason     Human-readable reason
     */
    function logRevocation(
        bytes32 agentId,
        address revokedBy,
        string calldata reason
    ) external;

    // ─────────────────────────────────────────────────────────────────
    // READ FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Gets a specific audit record by event ID
     * @param eventId  The audit entry identifier
     * @return record  Full AuditRecord struct
     */
    function getRecord(bytes32 eventId) external view returns (AuditRecord memory record);

    /**
     * @notice Gets total count of actions logged for an agent
     * @dev Used for pagination in dashboard queries
     * @param agentId  The agent
     * @return count   Total action count (including violations)
     */
    function getActionCount(bytes32 agentId) external view returns (uint256 count);

    /**
     * @notice Gets action count broken down by outcome
     * @param agentId      The agent
     * @return successes   Count of successful actions
     * @return violations  Count of blocked violations
     */
    function getActionStats(bytes32 agentId) external view returns (
        uint256 successes,
        uint256 violations
    );
}
```

---

## Storage Layout

```solidity
// AuditLogger.sol storage

// Event ID → AuditRecord
mapping(bytes32 => AuditRecord) private _records;

// Agent ID → list of event IDs (for agent history queries)
mapping(bytes32 => bytes32[]) private _agentEvents;

// Agent ID → count breakdown
mapping(bytes32 => uint256) private _successCounts;
mapping(bytes32 => uint256) private _violationCounts;

// Access control
address private _permissionVault;
address private _revocationRegistry;
address private _cidRelayer;          // Off-chain service authorised to add CIDs
```

---

## Event ID Derivation

```solidity
function _deriveEventId(
    bytes32 agentId,
    bytes32 userOpHash,
    uint256 blockNumber
) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(agentId, userOpHash, blockNumber));
}
```

The event ID is deterministic — the same action in the same block always produces the same event ID. This allows the off-chain indexer to reliably add the IPFS CID later.

---

## Two-Phase Audit Record Strategy

The audit trail uses a two-phase approach to keep the critical execution path cheap:

```
Phase 1 (synchronous, in validateUserOp):
  logAction() called with no IPFS CID
  → Emits ActionLogged event
  → Minimal gas cost (~30,000 gas)
  → Event indexed by The Graph immediately

Phase 2 (asynchronous, off-chain indexer):
  Transaction confirmed on-chain
  Off-chain indexer constructs full audit record JSON
  Uploads to IPFS via Pinata API
  Calls logActionWithCid(eventId, "ipfs://Qm...")
  → Emits AuditCidAdded event
  → Record is now fully anchored (on-chain hash ↔ IPFS full record)
```

**Why this works:** The on-chain event log is already immutable and tamper-evident. The IPFS CID addition is additive — it enriches the record but does not change the security guarantee.

---

## Full Audit Record JSON (IPFS)

The full record stored on IPFS contains everything the on-chain entry references plus rich detail:

```json
{
  "schemaVersion": "1.0",
  "bouclierEventId": "0xHASH",
  "agent": {
    "did": "did:ethr:base:0x...",
    "agentId": "0x...",
    "model": "claude-sonnet-4-6",
    "owner": "0xENTERPRISE"
  },
  "action": {
    "type": "swap",
    "userOpHash": "0x...",
    "txHash": "0x...",
    "blockNumber": 12345678,
    "timestamp": 1748000000,
    "timestampISO": "2026-03-17T14:30:00Z"
  },
  "target": {
    "contract": "0xUNISWAP_ROUTER",
    "protocol": "uniswap_v3",
    "functionSelector": "0x04e45aaf",
    "functionName": "exactInputSingle"
  },
  "params": {
    "tokenIn": "0xUSDC_ADDRESS",
    "tokenOut": "0xWETH_ADDRESS",
    "fee": 500,
    "amountIn": "300000000",
    "amountOutMinimum": "0"
  },
  "financials": {
    "valueUSD": "300.00",
    "gasUsed": 142000,
    "gasCostETH": "0.000142",
    "gasCostUSD": "0.28"
  },
  "permission": {
    "scopeId": "0xSCOPE_HASH",
    "dailyCapUSD": "2000.00",
    "dailyUsedBeforeTx": "800.00",
    "dailyUsedAfterTx": "1100.00"
  },
  "outcome": {
    "status": "success",
    "violationType": null
  }
}
```

---

## Compliance Mapping

Fields required for regulatory compliance (MAS and MiCA):

| Regulatory Requirement | Bouclier Field | Source |
|---|---|---|
| Agent identity | `agent.did` | AgentRegistry + on-chain |
| Action time | `action.timestamp` + `action.timestampISO` | block.timestamp |
| Action description | `action.type` + `target.functionName` | calldata parsing |
| Target system | `target.protocol` + `target.contract` | calldata + known protocol map |
| Financial value | `financials.valueUSD` | Chainlink oracle |
| Authorization proof | `permission.scopeId` | PermissionVault |
| Outcome | `outcome.status` | Transaction receipt |
| Operator trail | Revocation events | RevocationRegistry |

---

## Access Control

```
logAction()        → PermissionVault only
logViolation()     → PermissionVault only
logActionWithCid() → PermissionVault OR authorised CID relayer
logRevocation()    → RevocationRegistry only
getRecord()        → Anyone (public read)
getActionCount()   → Anyone (public read)
getActionStats()   → Anyone (public read)
```

---

## Security Considerations

| Risk | Description | Mitigation |
|---|---|---|
| Log tampering | An admin removes a record | `mapping` is append-only by implementation; no delete function exists |
| CID substitution | Off-chain indexer uploads wrong IPFS record | Event `AuditCidAdded` captures what CID was set and when; any discrepancy is visible |
| False logging | Unauthorized caller logs fake actions | `onlyPermissionVault` modifier on all write functions |
| Log flooding | Attacker generates millions of violation attempts to fill logs | Rate limiting in PermissionVault (max N violations per agent per minute before throttling) |
| IPFS unavailability | Record stored on IPFS becomes unavailable | On-chain data is sufficient for enforcement; IPFS is for compliance detail. Pinata redundancy. |

---

## Gas Estimates

| Function | Estimated Gas |
|---|---|
| `logAction()` | ~35,000 (1 struct write + array push + event) |
| `logViolation()` | ~28,000 (minimal struct write + event) |
| `logActionWithCid()` | ~22,000 (1 string write + event) |
| `getRecord()` | ~10,000 (SLOAD × 4) |
| `getActionCount()` | ~3,000 (1 SLOAD) |

---

## Test Cases Required

```
✓ logAction — only PermissionVault can call
✓ logAction — ActionLogged event emitted with correct fields
✓ logAction — eventId is deterministic and unique
✓ logAction — action count increments
✓ logViolation — emits ActionLogged with outcome = Violated
✓ logViolation — violation count increments separately from success count
✓ logActionWithCid — adds CID to existing record
✓ logActionWithCid — AuditCidAdded event emitted
✓ logActionWithCid — reverts if eventId doesn't exist
✓ logRevocation — RevocationLogged event emitted
✓ logRevocation — only RevocationRegistry can call
✓ getRecord — returns correct AuditRecord
✓ getActionStats — success/violation counts are accurate
✓ getActionCount — total count is successes + violations
✗ FUZZ: many logAction calls — all event IDs unique, never collide
✗ INVARIANT: records are never modified after creation (tamper-proof)
```

---

*Last Updated: March 2026*
