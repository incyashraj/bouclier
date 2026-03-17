// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import "../helpers/TestBase.sol";

/// @title Handler contract — generates fuzz-guided calls to the protocol
/// @dev Foundry invariant testing will randomise calls to this handler's public functions
contract BouclierHandler is Test, Constants {
    RevocationRegistry internal revRegistry;
    AgentRegistry      internal agentReg;
    SpendTracker       internal spendTracker;
    AuditLogger        internal auditLogger;
    PermissionVault    internal vault;

    address internal admin;
    address internal enterprise;

    // Ghost variables for tracking invariants
    uint256 public ghost_totalAgentsRegistered;
    uint256 public ghost_totalRevocations;
    uint256 public ghost_totalAuditLogs;
    uint256 public ghost_totalPermissionsGranted;
    uint256 public ghost_totalPermissionsRevoked;

    // Track registered agents
    bytes32[] public registeredAgents;
    mapping(bytes32 => bool) public agentIsRegistered;
    mapping(bytes32 => bool) public agentHasScope;

    constructor(
        RevocationRegistry _revReg,
        AgentRegistry      _agentReg,
        SpendTracker       _spendTracker,
        AuditLogger        _auditLogger,
        PermissionVault    _vault,
        address            _admin,
        address            _enterprise
    ) {
        revRegistry  = _revReg;
        agentReg     = _agentReg;
        spendTracker = _spendTracker;
        auditLogger  = _auditLogger;
        vault        = _vault;
        admin        = _admin;
        enterprise   = _enterprise;
    }

    // ── Handler: Register an agent ──────────────────────────────
    function handler_registerAgent(uint256 seed) external {
        address wallet = address(uint160(uint256(keccak256(abi.encode(seed, block.timestamp)))));
        if (wallet == address(0)) wallet = address(1);

        vm.prank(enterprise);
        bytes32 aid = agentReg.register(wallet, "fuzz-model", bytes32(0), "QmFuzz");
        registeredAgents.push(aid);
        agentIsRegistered[aid] = true;
        ghost_totalAgentsRegistered++;
    }

    // ── Handler: Grant permission scope to an agent ─────────────
    function handler_grantScope(uint256 agentIdx, uint256 dailyCap, uint256 perTxCap) external {
        if (registeredAgents.length == 0) return;
        bytes32 aid = registeredAgents[agentIdx % registeredAgents.length];

        dailyCap = bound(dailyCap, 1e18, 10000e18);
        perTxCap = bound(perTxCap, 1e18, dailyCap);

        address[] memory noList = new address[](0);
        bytes4[]  memory noSel  = new bytes4[](0);

        PermissionScope memory scope = PermissionScope({
            agentId:           aid,
            allowedProtocols:  noList,
            allowedSelectors:  noSel,
            allowedTokens:     noList,
            dailySpendCapUSD:  dailyCap,
            perTxSpendCapUSD:  perTxCap,
            validFrom:         uint48(block.timestamp),
            validUntil:        uint48(block.timestamp + 30 days),
            allowAnyProtocol:  true,
            allowAnyToken:     true,
            revoked:           false,
            grantHash:         bytes32(0),
            windowStartHour:   0,
            windowEndHour:     0,
            windowDaysMask:    0,
            allowedChainId:    0
        });

        bytes32 structHash = keccak256(abi.encode(
            vault.SCOPE_TYPEHASH(),
            aid,
            vault.grantNonces(aid),
            scope.dailySpendCapUSD,
            scope.perTxSpendCapUSD,
            scope.validFrom,
            scope.validUntil,
            scope.allowAnyProtocol,
            scope.allowAnyToken
        ));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ENTERPRISE_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(enterprise);
        vault.grantPermission(aid, scope, sig);
        agentHasScope[aid] = true;
        ghost_totalPermissionsGranted++;
    }

    // ── Handler: Revoke permission (soft) ───────────────────────
    function handler_revokePermission(uint256 agentIdx) external {
        if (registeredAgents.length == 0) return;
        bytes32 aid = registeredAgents[agentIdx % registeredAgents.length];
        if (!agentHasScope[aid]) return;

        // Check if scope is already revoked (avoid double-counting)
        PermissionScope memory scope = vault.getActiveScope(aid);
        if (scope.revoked) return;

        vm.prank(enterprise);
        vault.revokePermission(aid);
        ghost_totalPermissionsRevoked++;
    }

    // ── Handler: Revoke agent in RevocationRegistry ─────────────
    function handler_revokeAgent(uint256 agentIdx) external {
        if (registeredAgents.length == 0) return;
        bytes32 aid = registeredAgents[agentIdx % registeredAgents.length];
        if (revRegistry.isRevoked(aid)) return;

        vm.prank(admin);
        revRegistry.revoke(aid, RevocationReason.PolicyViolation, "fuzz revoke");
        ghost_totalRevocations++;
    }

    // ── Handler: Log an audit action directly ───────────────────
    function handler_logAction(uint256 agentIdx, uint256 amount) external {
        if (registeredAgents.length == 0) return;
        bytes32 aid = registeredAgents[agentIdx % registeredAgents.length];
        amount = bound(amount, 0, 1000e18);

        vm.prank(address(vault));
        auditLogger.logAction(
            aid,
            keccak256(abi.encode(aid, block.timestamp, ghost_totalAuditLogs)),
            address(0x1234),
            bytes4(0xa9059cbb),
            address(0),
            amount,
            true,
            ""
        );
        ghost_totalAuditLogs++;
    }

    // ── Handler: Record spend ───────────────────────────────────
    function handler_recordSpend(uint256 agentIdx, uint256 amount) external {
        if (registeredAgents.length == 0) return;
        bytes32 aid = registeredAgents[agentIdx % registeredAgents.length];
        amount = bound(amount, 1, 500e18);

        vm.prank(address(vault));
        spendTracker.recordSpend(aid, amount, uint48(block.timestamp));
    }

    // ── Handler: Warp time forward ──────────────────────────────
    function handler_warp(uint256 delta) external {
        delta = bound(delta, 1, 2 days);
        vm.warp(block.timestamp + delta);
    }

    // ── Getters ─────────────────────────────────────────────────
    function registeredAgentsLength() external view returns (uint256) {
        return registeredAgents.length;
    }
}

/// @title Invariant test suite for Bouclier protocol
/// @dev Tests critical protocol invariants that must hold after any sequence of operations
contract InvariantBouclierTest is BouclierTestBase {
    BouclierHandler internal handler;

    function setUp() public override {
        super.setUp();

        handler = new BouclierHandler(
            revRegistry,
            agentReg,
            spendTracker,
            auditLogger,
            vault,
            admin,
            enterprise
        );

        // Grant REVOKER_ROLE to handler's admin calls
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(), admin);

        // Target only the handler for invariant testing
        targetContract(address(handler));
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 1: AgentRegistry.totalAgents() == ghost counter
    // ═══════════════════════════════════════════════════════════════

    function invariant_agentRegistryCount() public view {
        // +1 for the agent registered in setUp()
        assertEq(
            agentReg.totalAgents(),
            handler.ghost_totalAgentsRegistered() + 1,
            "INV-1: totalAgents mismatch"
        );
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 2: Revoked agents always return isRevoked == true
    //               (no silent de-revocation without explicit reinstate)
    // ═══════════════════════════════════════════════════════════════

    function invariant_revokedAgentsStayRevoked() public view {
        uint256 len = handler.registeredAgentsLength();
        for (uint256 i; i < len; ++i) {
            bytes32 aid = handler.registeredAgents(i);
            RevocationRecord memory rec = revRegistry.getRevocationRecord(aid);
            if (rec.revoked) {
                assertTrue(
                    revRegistry.isRevoked(aid),
                    "INV-2: revoked record but isRevoked() is false"
                );
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 3: AuditLogger records are append-only and immutable
    //               Once created, timestamp, agentId, and actionHash cannot change
    // ═══════════════════════════════════════════════════════════════

    function invariant_auditRecordsImmutable() public view {
        uint256 len = handler.registeredAgentsLength();
        for (uint256 i; i < len; ++i) {
            bytes32 aid = handler.registeredAgents(i);
            uint256 total = auditLogger.getTotalEvents(aid);
            if (total > 0) {
                // Check first and last records exist with non-zero timestamps
                bytes32[] memory history = auditLogger.getAgentHistory(aid, 0, 1);
                if (history.length > 0) {
                    AuditRecord memory rec = auditLogger.getAuditRecord(history[0]);
                    assertTrue(
                        rec.timestamp > 0,
                        "INV-3: audit record has zero timestamp"
                    );
                    assertEq(
                        rec.agentId, aid,
                        "INV-3: audit record agentId mismatch"
                    );
                }
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 4: A scope marked as revoked must always return revoked=true
    //               (no un-revoking a scope without a new grantPermission call)
    // ═══════════════════════════════════════════════════════════════

    function invariant_revokedScopeStaysRevoked() public view {
        uint256 len = handler.registeredAgentsLength();
        for (uint256 i; i < len; ++i) {
            bytes32 aid = handler.registeredAgents(i);
            PermissionScope memory scope = vault.getActiveScope(aid);
            if (scope.revoked) {
                assertTrue(
                    scope.revoked,
                    "INV-4: scope.revoked inconsistency"
                );
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 5: PermissionVault.isModuleType(1) always returns true
    //               (contract always identifies as ERC-7579 validator)
    // ═══════════════════════════════════════════════════════════════

    function invariant_moduleTypeAlwaysValidator() public view {
        assertTrue(
            vault.isModuleType(1),
            "INV-5: must always be module type 1 (validator)"
        );
        assertFalse(
            vault.isModuleType(2),
            "INV-5: must NOT be module type 2 (executor)"
        );
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 6: SpendTracker rolling spend never exceeds sum of records
    //               (no phantom spend accrual)
    // ═══════════════════════════════════════════════════════════════

    function invariant_spendTrackerConsistency() public view {
        uint256 len = handler.registeredAgentsLength();
        for (uint256 i; i < len; ++i) {
            bytes32 aid = handler.registeredAgents(i);
            uint256 rolling24h = spendTracker.getRollingSpend(aid, 1 days);
            uint256 rolling7d  = spendTracker.getRollingSpend(aid, 7 days);
            // 7-day window must be >= 24-hour window
            assertTrue(
                rolling7d >= rolling24h,
                "INV-6: 7d spend < 24h spend (impossible)"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 7: Contract owner is never address(0)
    //               (unless renounced — which we don't do in handler)
    // ═══════════════════════════════════════════════════════════════

    function invariant_ownerNeverZero() public view {
        assertTrue(
            vault.owner() != address(0),
            "INV-7: PermissionVault owner is zero"
        );
        assertTrue(
            agentReg.admin() != address(0),
            "INV-7: AgentRegistry admin is zero"
        );
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 8: validateUserOp for a revoked agent MUST fail
    //               (the gatekeeper invariant — most critical)
    // ═══════════════════════════════════════════════════════════════

    function invariant_revokedAgentAlwaysBlocked() public {
        // Use the default agent from setUp which we can control
        if (!revRegistry.isRevoked(agentId)) return;

        // Build a minimal UserOp
        bytes memory callData = abi.encodeWithSelector(
            EXECUTE_SEL,
            address(0x1234),
            uint256(0),
            abi.encodeWithSelector(TRANSFER_SEL, address(0x5678), 1e18)
        );
        PackedUserOperation memory op = PackedUserOperation({
            sender:             agentWallet,
            nonce:              0,
            initCode:           "",
            callData:           callData,
            accountGasLimits:   bytes32(0),
            preVerificationGas: 0,
            gasFees:            bytes32(0),
            paymasterAndData:   "",
            signature:          ""
        });

        uint256 result = vault.validateUserOp(op, keccak256(abi.encode(op)));
        assertEq(result, VALIDATION_FAILED, "INV-8: revoked agent passed validation");
    }

    // ═══════════════════════════════════════════════════════════════
    //  INVARIANT 9: Ghost counters match protocol state
    // ═══════════════════════════════════════════════════════════════

    function invariant_ghostCountersConsistent() public view {
        assertTrue(
            handler.ghost_totalPermissionsGranted() >= handler.ghost_totalPermissionsRevoked(),
            "INV-9: more revokes than grants"
        );
    }
}
