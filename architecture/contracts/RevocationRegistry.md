# RevocationRegistry.sol — Contract Architecture

> **Contract:** `RevocationRegistry.sol`  
> **Layer:** Revocation Layer  
> **Dependencies:** None (root contract, no external dependencies)  
> **Used by:** `PermissionVault.sol`, `AuditLogger.sol`, SDK revocation flow  
> **This contract is the kill switch for the entire protocol.**

---

## Purpose

`RevocationRegistry` maintains the definitive, on-chain record of which agents have been revoked. It is a standalone contract with no dependencies, intentionally kept minimal for maximum reliability.

**Design principles:**
- **Single source of truth:** All revocation state lives here. No other contract maintains a local revocation flag.
- **Monotonic:** An agent can be revoked, but revocation cannot be undone without a deliberate reinstatement action (with a timelock).
- **Instantly readable:** `isRevoked()` is a single SLOAD — as cheap as possible.
- **Auditable:** Every revocation carries an on-chain reason + revoker address permanently.

---

## Full Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRevocationRegistry {

    // ─────────────────────────────────────────────────────────────────
    // STRUCTS
    // ─────────────────────────────────────────────────────────────────

    enum RevocationReason {
        Suspicious,        // Unusual activity detected
        Compromised,       // Agent key believed compromised
        Expired,           // Permission scope expired manually
        PolicyViolation,   // Agent violated terms or policy
        UserRequested,     // Owner requested voluntary revocation
        Regulatory,        // Regulatory/compliance requirement
        Other              // Custom reason (provided in customReason string)
    }

    struct RevocationRecord {
        bytes32          agentId;
        address          revokedBy;       // Who triggered revocation
        RevocationReason reason;
        string           customReason;   // Optional human-readable detail
        uint48           revokedAt;      // block.timestamp
        uint64           revokedAtBlock; // block.number
        bool             reinstated;     // true if revocation was undone
        uint48           reinstatedAt;   // If reinstated, when
        address          reinstatedBy;
    }

    // ─────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────

    event AgentRevoked(
        bytes32 indexed agentId,
        address indexed revokedBy,
        RevocationReason reason,
        string          customReason,
        uint48          timestamp,
        uint64          blockNumber
    );

    event AgentReinstated(
        bytes32 indexed agentId,
        address indexed reinstatedBy,
        string          reason,
        uint48          timestamp
    );

    // ─────────────────────────────────────────────────────────────────
    // WRITE FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Revokes an agent
     * @dev Callable by:
     *      1. Agent owner (always can revoke their own agent)
     *      2. Protocol admin (emergency revocation)
     *      3. PermissionVault (can auto-revoke after N violations)
     *      IDEMPOTENT — revoking an already-revoked agent does not revert.
     *
     * @param agentId       The agent to revoke
     * @param reason        Structured reason code
     * @param customReason  Human-readable detail (stored on-chain)
     */
    function revoke(
        bytes32 agentId,
        RevocationReason reason,
        string calldata customReason
    ) external;

    /**
     * @notice Emergency batch revocation — revokes multiple agents in one transaction
     * @dev Protocol admin only. Used when a single compromised system affects many agents.
     * @param agentIds      Array of agents to revoke
     * @param reason        Single reason applied to all
     * @param customReason  Detail
     */
    function batchRevoke(
        bytes32[] calldata agentIds,
        RevocationReason reason,
        string calldata customReason
    ) external;

    /**
     * @notice Reinstates a previously revoked agent (with timelock)
     * @dev Only the agent owner can reinstate their own agent.
     *      Protocol admin can reinstate any agent.
     *      Reinstatement requires a 24-hour timelock from revocation.
     *      This prevents attacker from revoking + immediately reinstating.
     * @param agentId  The agent to reinstate
     * @param reason   Why reinstatement is warranted
     */
    function reinstate(
        bytes32 agentId,
        string calldata reason
    ) external;

    // ─────────────────────────────────────────────────────────────────
    // READ FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Checks if an agent is currently revoked
     * @dev This is the HOT PATH function — called on every validateUserOp.
     *      MUST be a single SLOAD. No external calls.
     * @param agentId  The agent to check
     * @return revoked True if revoked AND not subsequently reinstated
     */
    function isRevoked(bytes32 agentId) external view returns (bool revoked);

    /**
     * @notice Gets the full revocation record for an agent
     * @dev Returns the LATEST revocation (agents can be revoked, reinstated, revoked again)
     * @param agentId  The agent to query
     * @return record  Full RevocationRecord (default empty struct if never revoked)
     */
    function getRevocationRecord(bytes32 agentId) external view returns (RevocationRecord memory record);

    /**
     * @notice Gets all revocation events for an agent (full history)
     * @dev An agent can be revoked/reinstated/revoked multiple times — all are recorded
     * @param agentId  The agent
     * @return records Array of all RevocationRecords in chronological order
     */
    function getRevocationHistory(bytes32 agentId) external view returns (RevocationRecord[] memory records);

    /**
     * @notice Returns the timestamp when an agent can be reinstated (24h after revocation)
     * @dev Returns 0 if the agent is not currently revoked
     * @param agentId  The agent
     * @return canReinstateAt  Unix timestamp after which reinstatement is possible
     */
    function getReinstatementAvailableAt(bytes32 agentId) external view returns (uint48 canReinstateAt);

    /**
     * @notice Gets all currently-revoked agent IDs for an owner
     * @dev Used by dashboard to show operator "agents needing attention"
     * @param owner  The enterprise/developer address
     * @return agentIds  All revoked agent IDs belonging to this owner
     */
    function getRevokedAgents(address owner) external view returns (bytes32[] memory agentIds);
}
```

---

## Storage Layout

```solidity
// RevocationRegistry.sol storage

// Agent ID → current revocation status (hot path: 1 SLOAD)
mapping(bytes32 => bool) private _isRevoked;

// Agent ID → latest RevocationRecord (for quick lookup)
mapping(bytes32 => RevocationRecord) private _latestRecord;

// Agent ID → all historical records (revoke, reinstate, revoke again)
mapping(bytes32 => RevocationRecord[]) private _history;

// Owner address → list of their revoked agent IDs
mapping(address => bytes32[]) private _ownerRevocations;

// Access control
address private _protocol_admin;          // Protocol-level admin (multisig)
address private _permissionVault;         // Can auto-revoke after N violations
mapping(address => bool) private _authorised_revokers; // Additional authorised callers
```

---

## Revocation Flow (End-to-End)

### Standard Revocation (Human-Triggered)

```
1. Human clicks "Revoke Agent" in dashboard
         ↓
2. Dashboard calls API: POST /v1/agents/{did}/revoke  { reason: "Suspicious activity" }
         ↓
3. API updates Redis: SET revoked:{agentId} true (EX 3600)  ← IMMEDIATE (< 100ms)
         ↓
4. API broadcasts transaction: RevocationRegistry.revoke(agentId, Suspicious, "...")
         ↓
5. On-chain revocation confirmed (Base: ~2s average block time)
         ↓
6. AuditLogger.logRevocation() emitted
         ↓
7. PermissionVault.emergencyRevoke() called to zero out all scopes
         ↓
8. Any pending UserOps in bundler mempool → rejected (validateUserOp returns FAILED)
         ↓
9. Dashboard shows "Revoked" status with timestamp + reason
        10. Slack/email webhook fired: "Agent XYZ was revoked by 0xOPERATOR at 14:32"
```

**Total time to agent being unable to execute:** < 2 seconds (Redis flag precedes on-chain)

### Auto-Revocation (Protocol-Triggered)

PermissionVault can trigger auto-revocation when violation thresholds are exceeded:

```solidity
// In PermissionVault: if agent triggers > 10 violations in 1 hour, auto-revoke
if (_violationCounts[agentId] > AUTO_REVOKE_THRESHOLD) {
    revocationRegistry.revoke(
        agentId,
        RevocationReason.PolicyViolation,
        "Auto-revoked: excessive violation attempts"
    );
}
```

### Redis Cache Invalidation

The Redis cache layer ensures sub-second revocation propagation:

```
Redis key: "revoked:{agentId}" → "1"
TTL: 3600 seconds (refreshed each time on-chain check confirms)
SDK check order:
  1. Redis cache (< 1ms)
  2. On-chain SLOAD (fallback, ~100ms)
```

---

## Reinstatement Timelock

**Why a timelock?**

Without a timelock, an attacker who gains momentary access to an owner's dashboard could:
1. Revoke the agent (to get a clean slate)
2. Immediately reinstate the agent with a wider scope

The 24-hour timelock ensures any revocation has a window for human review before reinstatement.

```solidity
function reinstate(bytes32 agentId, string calldata reason) external {
    RevocationRecord storage record = _latestRecord[agentId];
    
    require(record.revokedAt != 0, "not revoked");
    require(!record.reinstated, "already reinstated");
    require(
        block.timestamp >= record.revokedAt + 24 hours,
        "reinstatement timelock: must wait 24h after revocation"
    );
    
    // Access check: only owner or admin
    _requireOwnerOrAdmin(agentId);
    
    record.reinstated = true;
    record.reinstatedAt = uint48(block.timestamp);
    record.reinstatedBy = msg.sender;
    
    _isRevoked[agentId] = false;
    
    emit AgentReinstated(agentId, msg.sender, reason, uint48(block.timestamp));
}
```

---

## Access Control Matrix

| Function | Agent Owner | Protocol Admin | PermissionVault | Public |
|---|---|---|---|---|
| `revoke()` | ✓ their agents | ✓ any agent | ✓ auto-revoke only | ✗ |
| `batchRevoke()` | ✗ | ✓ | ✗ | ✗ |
| `reinstate()` | ✓ their agents | ✓ any agent | ✗ | ✗ |
| `isRevoked()` | ✓ | ✓ | ✓ | ✓ (public) |
| `getRevocationRecord()` | ✓ | ✓ | ✓ | ✓ (public) |
| `getRevocationHistory()` | ✓ | ✓ | ✓ | ✓ (public) |
| `getRevokedAgents()` | ✓ | ✓ | ✗ | ✗ |

---

## Security Considerations

| Risk | Description | Mitigation |
|---|---|---|
| Revocation bypass | Somehow execute a tx after revocation | Redis + on-chain dual check; both must pass |
| Revocation front-running | Attacker in mempool sees revocation tx + front-runs with large spend | Revocation via Flashbots Protect; Redis flag set before tx broadcast |
| Reinstatement abuse | Owner reinstates revoked agent immediately | 24h timelock enforced on-chain |
| batchRevoke abuse | Admin revokes all agents maliciously | Multisig required for admin; 2-of-3 signature threshold |
| isRevoked() caching wrong state | Redis cache shows not-revoked after on-chain revoke | Cache TTL is 1h; on-chain is always ground truth; SDK re-checks on-chain every N calls |
| Revocation reason poisoning | Malicious string in customReason | String stored on-chain but never executed; max length enforced (256 chars) |

---

## Test Cases Required

```
✓ revoke() — owner can revoke their agent
✓ revoke() — non-owner cannot revoke (access control)
✓ revoke() — AgentRevoked event emitted with all fields
✓ revoke() — isRevoked() returns true immediately after
✓ revoke() — idempotent: revoking already-revoked agent doesn't revert
✓ batchRevoke() — admin revokes multiple agents in one tx
✓ batchRevoke() — non-admin cannot batch revoke
✓ reinstate() — owner can reinstate after 24h timelock
✓ reinstate() — reinstatement attempt before 24h reverts
✓ reinstate() — isRevoked() returns false after reinstatement
✓ reinstate() — non-owner cannot reinstate
✓ isRevoked() — returns false for unregistered/never-revoked agent
✓ getRevocationRecord() — returns correct record fields
✓ getRevocationHistory() — returns all records including multiple revoke/reinstate cycles
✓ getReinstatementAvailableAt() — returns correct timestamp
✓ getRevokedAgents() — returns all revoked agents for an owner
✗ FUZZ: isRevoked() ALWAYS returns true for revoked agents (no bypass)
✗ INVARIANT: after revoke(), no tx from that agent can pass validateUserOp()
✗ INVARIANT: reinstate() cannot execute if block.timestamp < revokedAt + 24h
```

---

## Gas Estimates

| Function | Estimated Gas |
|---|---|
| `revoke()` | ~45,000 (2 storage writes + event + history push) |
| `isRevoked()` | ~2,200 (1 SLOAD) |
| `batchRevoke(10 agents)` | ~300,000 (~30k × 10, some shared overhead) |
| `reinstate()` | ~35,000 (2 storage writes + event) |
| `getRevocationRecord()` | ~8,000 (struct SLOAD) |

`isRevoked()` at ~2,200 gas is the critical metric — it's called on every single agent transaction. This must remain a bare SLOAD with no external calls.

---

*Last Updated: March 2026*
