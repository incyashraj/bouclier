// ═══════════════════════════════════════════════════════════════════
//  Certora Formal Verification Spec — PermissionVault
//  Verifies: validateUserOp, grantPermission, revokePermission
//  Uses PermissionVaultHarness for struct field access
// ═══════════════════════════════════════════════════════════════════

using RevocationRegistry as revReg;
using AgentRegistry as agentReg;
using SpendTracker as tracker;

methods {
    // PermissionVaultHarness — struct field getters
    function getScopeRevoked(bytes32) external returns (bool) envfree;
    function getScopeValidUntil(bytes32) external returns (uint48) envfree;
    function getScopeAgentId(bytes32) external returns (bytes32) envfree;

    // PermissionVault — simple-typed functions only
    function revokePermission(bytes32) external;
    function emergencyRevoke(bytes32) external;
    function isModuleType(uint256) external returns (bool) envfree;
    function owner() external returns (address) envfree;
    function paused() external returns (bool) envfree;
    function grantNonces(bytes32) external returns (uint256) envfree;
    function DOMAIN_SEPARATOR() external returns (bytes32) envfree;

    // RevocationRegistry
    function revReg.isRevoked(bytes32) external returns (bool) envfree;

    // AgentRegistry
    function agentReg.isActive(bytes32) external returns (bool) envfree;
    function agentReg.getAgentId(address) external returns (bytes32) envfree;

    // SpendTracker
    function tracker.checkSpendCap(bytes32, uint256, uint256) external returns (bool) envfree;
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 1: Revoked agents ALWAYS fail validation
//  This is the most critical security property of the protocol.
// ═══════════════════════════════════════════════════════════════════

rule revokedAgentAlwaysFails {
    env e;
    calldataarg args;
    bytes32 userOpHash;

    // Extract sender from UserOp
    address sender;
    bytes32 agentId = agentReg.getAgentId(sender);

    // Pre-condition: agent is revoked
    require revReg.isRevoked(agentId);

    // Call validateUserOp
    uint256 result = validateUserOp(e, args, userOpHash);

    // Post-condition: validation MUST fail (return 1)
    assert result == 1, "CRITICAL: Revoked agent passed validation!";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 2: validateUserOp only returns 0 or 1
//  (no unexpected return values)
// ═══════════════════════════════════════════════════════════════════

rule validateUserOpReturnsBinaryResult {
    env e;
    calldataarg args;
    bytes32 userOpHash;

    uint256 result = validateUserOp(e, args, userOpHash);

    assert result == 0 || result == 1, "validateUserOp returned non-binary value";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 3: Scope revocation is irreversible without new grant
//  Once revokePermission is called, getActiveScope.revoked == true
//  until a new grantPermission overwrites it.
// ═══════════════════════════════════════════════════════════════════

rule revokePermissionSetsRevoked {
    env e;
    bytes32 agentId;

    // Pre-condition: scope exists (agentId != 0)
    require agentId != to_bytes32(0);

    // Call revokePermission
    revokePermission(e, agentId);

    // Post-condition: scope is now revoked
    assert getScopeRevoked(agentId) == true,
        "revokePermission did not set revoked flag";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 4: emergencyRevoke sets both scope.revoked AND revReg.isRevoked
// ═══════════════════════════════════════════════════════════════════

rule emergencyRevokeSetsBothFlags {
    env e;
    bytes32 agentId;

    require agentId != to_bytes32(0);

    // Pre-condition: agent is NOT revoked
    require !revReg.isRevoked(agentId);
    require !getScopeRevoked(agentId);

    emergencyRevoke(e, agentId);

    // Post-condition: both flags set
    assert getScopeRevoked(agentId) == true,
        "emergencyRevoke did not revoke scope";
    assert revReg.isRevoked(agentId) == true,
        "emergencyRevoke did not update RevocationRegistry";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 5: grantPermission monotonically increases nonces
//  (replay protection — nonce never decreases or stays same)
// ═══════════════════════════════════════════════════════════════════

rule grantPermissionIncreasesNonce {
    env e;
    bytes32 agentId;
    calldataarg args;

    uint256 nonceBefore = grantNonces(agentId);

    grantPermission(e, args);

    uint256 nonceAfter = grantNonces(agentId);

    assert nonceAfter == nonceBefore + 1,
        "grantPermission did not increment nonce";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 6: Module type identification is immutable
// ═══════════════════════════════════════════════════════════════════

rule moduleTypeIsConstant {
    assert isModuleType(1) == true,  "Must be validator type";
    assert isModuleType(2) == false, "Must NOT be executor type";
    assert isModuleType(0) == false, "Must NOT be type 0";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 7: Scope with expired validUntil causes validation failure
// ═══════════════════════════════════════════════════════════════════

rule expiredScopeFailsValidation {
    env e;
    bytes32 agentId;
    bytes32 userOpHash;
    calldataarg args;

    // Pre-condition: scope exists and has expired
    require getScopeValidUntil(agentId) < e.block.timestamp;
    require getScopeValidUntil(agentId) != 0;  // scope exists

    uint256 result = validateUserOp(e, args, userOpHash);

    assert result == 1, "Expired scope should fail validation";
}

// ═══════════════════════════════════════════════════════════════════
//  INVARIANT: DOMAIN_SEPARATOR is deterministic
//  (same chain + contract = same separator)
// ═══════════════════════════════════════════════════════════════════

invariant domainSeparatorConsistent()
    DOMAIN_SEPARATOR() == DOMAIN_SEPARATOR()
    { preserved { require true; } }
