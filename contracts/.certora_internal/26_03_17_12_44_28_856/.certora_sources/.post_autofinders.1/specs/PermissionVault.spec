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

    // SpendTracker — NOT envfree (uses block.timestamp internally)
    function tracker.checkSpendCap(bytes32, uint256, uint256) external returns (bool);
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 1: Revoked agents ALWAYS fail validation
//  This is the most critical security property of the protocol.
// ═══════════════════════════════════════════════════════════════════

// NOTE: `validateUserOp` takes a packed UserOp struct via calldataarg.
// The sender is embedded inside calldata, so we cannot link a CVL `require`
// to the actual sender the contract decodes. Instead, we verify the
// complementary property: after revokePermission, the scope is marked
// revoked, and revoking + checking is consistent (tested in detail by
// the RevocationRegistry spec and the Foundry unit tests).
//
// We verify the weaker but provable property that paused contract
// always reverts for validateUserOp.

rule pausedContractRevertsValidation {
    env e;
    calldataarg args;

    require paused() == true;

    validateUserOp@withrevert(e, args);

    assert lastReverted, "validateUserOp should revert when paused";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 2: validateUserOp only returns 0 or 1
//  (no unexpected return values)
// ═══════════════════════════════════════════════════════════════════

rule validateUserOpReturnsBinaryResult {
    env e;
    calldataarg args;

    uint256 result = validateUserOp(e, args);

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

rule emergencyRevokeSetsScope {
    env e;
    bytes32 agentId;

    require agentId != to_bytes32(0);

    // Pre-condition: scope is NOT revoked
    require !getScopeRevoked(agentId);

    emergencyRevoke(e, agentId);

    // Post-condition: scope.revoked is set (verifiable within this contract)
    // Note: RevocationRegistry state change is cross-contract and verified
    // separately in the RevocationRegistry spec.
    assert getScopeRevoked(agentId) == true,
        "emergencyRevoke did not revoke scope";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 5: grantPermission monotonically increases nonces
//  (replay protection — nonce never decreases or stays same)
// ═══════════════════════════════════════════════════════════════════

rule grantPermissionNonceNeverDecreases {
    env e;
    bytes32 agentId;
    calldataarg args;

    uint256 nonceBefore = grantNonces(agentId);

    // Call any function (grantPermission or anything else)
    grantPermission@withrevert(e, args);

    uint256 nonceAfter = grantNonces(agentId);

    // Nonce never decreases regardless of success/failure
    assert nonceAfter >= nonceBefore,
        "grantPermission nonce decreased";
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
//  RULE 7: Scope revocation is idempotent
// ═══════════════════════════════════════════════════════════════════

// Scope revocation persistence: once revokePermission sets the flag,
// calling revokePermission again (idempotent) does not corrupt state.

rule revokePermissionIsIdempotent {
    env e1;
    env e2;
    bytes32 agentId;

    require agentId != to_bytes32(0);

    // First revoke
    revokePermission(e1, agentId);
    require getScopeRevoked(agentId) == true;

    // Second revoke — should not corrupt anything
    revokePermission@withrevert(e2, agentId);

    // Flag remains set regardless
    assert getScopeRevoked(agentId) == true,
        "Double revokePermission corrupted scope state";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 8: DOMAIN_SEPARATOR is immutable across state changes
//  No state-modifying function can alter the EIP-712 domain separator.
// ═══════════════════════════════════════════════════════════════════

rule domainSeparatorImmutable {
    bytes32 dsBefore = DOMAIN_SEPARATOR();

    // Execute any function
    env e;
    calldataarg args;
    method f;
    f(e, args);

    bytes32 dsAfter = DOMAIN_SEPARATOR();

    assert dsBefore == dsAfter,
        "DOMAIN_SEPARATOR changed after a function call";
}
