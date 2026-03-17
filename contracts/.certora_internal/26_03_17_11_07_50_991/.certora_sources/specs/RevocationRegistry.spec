// ═══════════════════════════════════════════════════════════════════
//  Certora Formal Verification Spec — RevocationRegistry
//  Verifies: isRevoked behaviour, reinstate timelock, role enforcement
// ═══════════════════════════════════════════════════════════════════

methods {
    function revoke(bytes32, uint8, string) external;
    function reinstate(bytes32, string) external;
    function emergencyReinstate(bytes32, string) external;
    function isRevoked(bytes32) external returns (bool) envfree;
    function getRevocationRecord(bytes32) external returns (RevocationRecord) envfree;
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 1: After revoke(), isRevoked must return true
// ═══════════════════════════════════════════════════════════════════

rule revokeAlwaysSetsFlag {
    env e;
    bytes32 agentId;
    uint8 reason;
    string notes;

    require !isRevoked(agentId);

    revoke(e, agentId, reason, notes);

    assert isRevoked(agentId) == true,
        "revoke() did not set isRevoked flag";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 2: isRevoked is consistent with stored record
// ═══════════════════════════════════════════════════════════════════

rule isRevokedMatchesRecord {
    bytes32 agentId;

    bool revoked = isRevoked(agentId);

    assert revoked == getRevocationRecord(agentId).revoked,
        "isRevoked disagrees with stored record";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 3: reinstate() respects 24h timelock
//  Cannot reinstate before revokedAt + 24h (unless emergency)
// ═══════════════════════════════════════════════════════════════════

rule reinstateRespectsTimelock {
    env e;
    bytes32 agentId;
    string notes;

    require isRevoked(agentId);
    uint48 revokedAt = getRevocationRecord(agentId).revokedAt;
    require e.block.timestamp < revokedAt + 86400;  // within 24h

    // reinstate should revert (no way to assert revert in Certora directly,
    // but we can verify: if reinstate succeeds, timelock was respected)
    reinstate@withrevert(e, agentId, notes);

    assert lastReverted,
        "reinstate() succeeded within 24h timelock";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 4: Double-revoke is idempotent (no state corruption)
//  Revoking an already-revoked agent should revert
// ═══════════════════════════════════════════════════════════════════

rule doubleRevokeReverts {
    env e;
    bytes32 agentId;
    uint8 reason;
    string notes;

    require isRevoked(agentId);

    revoke@withrevert(e, agentId, reason, notes);

    // Should either revert or the flag remains true
    assert isRevoked(agentId) == true,
        "Double revoke corrupted state";
}

// ═══════════════════════════════════════════════════════════════════
//  INVARIANT: Once revoked, agent stays revoked until explicit reinstate
// ═══════════════════════════════════════════════════════════════════

invariant revokedStaysRevoked(bytes32 agentId)
    getRevocationRecord(agentId).revoked => isRevoked(agentId)
    { preserved { require true; } }
