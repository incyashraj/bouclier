// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import "../helpers/Constants.sol";
import "../../src/RevocationRegistry.sol";
import "../../src/AgentRegistry.sol";
import "../../src/SpendTracker.sol";
import "../../src/AuditLogger.sol";
import "../../src/PermissionVault.sol";
import "../../src/interfaces/IBouclier.sol";

/// @dev Minimal mock Chainlink aggregator — returns a fixed price.
contract MockFeedE2E {
    int256  public answer;
    uint8   public decimals;
    uint256 public updatedAt;

    constructor(int256 _answer, uint8 _decimals) {
        answer    = _answer;
        decimals  = _decimals;
        updatedAt = block.timestamp;
    }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, answer, block.timestamp, updatedAt, 1);
    }
}

/// @title  Bouclier E2E: Register → Scope → Block → Revoke
/// @notice Four-step scenario in a single test:
///           1. Register an agent on-chain
///           2. Grant a restricted permission scope (USDC-only, WETH target only)
///           3. Agent attempts an out-of-scope action (calls Uniswap) → BLOCKED
///           4. Emergency revoke the agent — verify it completes in < 3 s of gas
contract E2ERegisterScopeBlockRevokeTest is Test, Constants {

    // ── Contracts ──────────────────────────────────────────────────
    RevocationRegistry internal revRegistry;
    AgentRegistry      internal agentReg;
    SpendTracker       internal spendTracker;
    AuditLogger        internal auditLogger;
    PermissionVault    internal vault;
    MockFeedE2E        internal usdcFeed;

    // ── Actors ─────────────────────────────────────────────────────
    address internal owner;
    address internal agentWallet;
    address internal stranger;
    address internal admin;

    // ── Protocol addresses ─────────────────────────────────────────
    address internal constant UNISWAP_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;
    bytes4  internal constant EXACT_INPUT_SEL = bytes4(keccak256(
        "exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))"
    ));

    function setUp() public {
        vm.warp(7 days);

        owner       = vm.addr(ENTERPRISE_KEY);
        agentWallet = vm.addr(AGENT_KEY);
        stranger    = vm.addr(STRANGER_KEY);
        admin       = address(this);

        // Deploy mock USDC oracle (1 USDC = $1, 8-decimal feed)
        usdcFeed = new MockFeedE2E(1e8, 8);

        // Deploy all five Bouclier contracts
        revRegistry  = new RevocationRegistry(admin);
        agentReg     = new AgentRegistry(admin);
        spendTracker = new SpendTracker(admin);
        auditLogger  = new AuditLogger(admin);
        vault = new PermissionVault(
            admin,
            address(agentReg),
            address(revRegistry),
            address(spendTracker),
            address(auditLogger)
        );

        // Wire operational roles
        spendTracker.grantRole(spendTracker.VAULT_ROLE(), address(vault));
        auditLogger.grantRole(auditLogger.LOGGER_ROLE(),  address(vault));
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(),  address(vault));

        // Register USDC price feed
        spendTracker.setPriceFeed(USDC, address(usdcFeed));
    }

    // ════════════════════════════════════════════════════════════════════════════
    // THE FOUR-STEP E2E SCENARIO
    // ════════════════════════════════════════════════════════════════════════════

    // ── State shared across steps ──────────────────────────────────
    bytes32 internal agentId;

    function _step1_register() internal {
        vm.prank(owner);
        agentId = agentReg.register(
            agentWallet, "gpt-4o", bytes32(0), "QmE2ECIDforDemoAgent"
        );
        AgentRecord memory rec = agentReg.resolve(agentId);
        assertEq(rec.agentAddress, agentWallet, "agent wallet mismatch");
        assertEq(rec.owner, owner, "owner mismatch");
        assertTrue(agentReg.isActive(agentId), "agent should be active");
        emit log_named_bytes32("Step 1 PASS - Agent registered", agentId);
    }

    function _step2_grantScope() internal {
        address[] memory protos = new address[](1);
        protos[0] = WETH;
        address[] memory tokens = new address[](1);
        tokens[0] = USDC;

        PermissionScope memory scope = PermissionScope({
            agentId:          agentId,
            allowedProtocols: protos,
            allowedSelectors: new bytes4[](0),
            allowedTokens:    tokens,
            dailySpendCapUSD: USD_100,
            perTxSpendCapUSD: USD_50,
            validFrom:        uint48(block.timestamp),
            validUntil:       uint48(block.timestamp + 30 days),
            allowAnyProtocol: false,
            allowAnyToken:    false,
            revoked:          false,
            grantHash:        bytes32(0),
            windowStartHour:  0,
            windowEndHour:    0,
            windowDaysMask:   0,
            allowedChainId:   0
        });

        bytes memory sig = _signScopeE2E(scope);
        vm.prank(owner);
        vault.grantPermission(agentId, scope, sig);

        PermissionScope memory stored = vault.getActiveScope(agentId);
        assertEq(stored.dailySpendCapUSD, USD_100, "daily cap mismatch");
        assertFalse(stored.allowAnyProtocol, "should be restricted");
        emit log("Step 2 PASS - Restricted scope granted (WETH only, $100/day, $50/tx)");
    }

    function _signScopeE2E(PermissionScope memory scope) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(abi.encode(
            vault.SCOPE_TYPEHASH(),
            scope.agentId,
            vault.grantNonces(agentId),
            scope.dailySpendCapUSD,
            scope.perTxSpendCapUSD,
            scope.validFrom,
            scope.validUntil,
            scope.allowAnyProtocol,
            scope.allowAnyToken
        ));
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ENTERPRISE_KEY, digest);
        return abi.encodePacked(r, s, v);
    }

    function _step3_outOfScopeBlocked() internal {
        bytes memory innerData = abi.encodePacked(EXACT_INPUT_SEL, new bytes(64));
        bytes memory callData  = abi.encodeWithSelector(EXECUTE_SEL, UNISWAP_ROUTER, 0, innerData);
        PackedUserOperation memory badOp = PackedUserOperation({
            sender: agentWallet, nonce: 0, initCode: "",
            callData: callData, accountGasLimits: bytes32(0),
            preVerificationGas: 0, gasFees: bytes32(0),
            paymasterAndData: "", signature: ""
        });

        vm.expectEmit(false, false, false, false);
        emit IPermissionVault.PermissionViolation(
            agentId, UNISWAP_ROUTER, EXACT_INPUT_SEL, "PROTOCOL_NOT_ALLOWED"
        );

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(badOp, keccak256(abi.encode(badOp)));
        assertEq(result, VALIDATION_FAILED, "out-of-scope action should be BLOCKED");

        uint256 events = auditLogger.getTotalEvents(agentId);
        assertGe(events, 1, "denial should be logged");
        emit log("Step 3 PASS - Out-of-scope Uniswap call BLOCKED (PROTOCOL_NOT_ALLOWED)");
    }

    function _step4_emergencyRevoke() internal {
        uint256 gasBefore = gasleft();
        vm.prank(owner);
        vault.emergencyRevoke(agentId);
        uint256 revokeGas = gasBefore - gasleft();

        assertTrue(revRegistry.isRevoked(agentId), "agent should be revoked");
        assertTrue(vault.getActiveScope(agentId).revoked, "scope should be revoked");

        // Post-revoke: ANY action must fail
        PackedUserOperation memory op = _buildPostRevokeOp();
        vm.prank(ENTRY_POINT);
        uint256 postResult = vault.validateUserOp(op, keccak256(abi.encode(op)));
        assertEq(postResult, VALIDATION_FAILED, "revoked agent permanently blocked");

        // Gas: 500k gas ≈ 17ms on 30M gas/s chain — well under 3 seconds
        assertLt(revokeGas, 500_000, "emergencyRevoke should be cheap");
        emit log("Step 4 PASS - Emergency revoke completed");
        emit log_named_uint("  Revoke gas used", revokeGas);
    }

    function _buildPostRevokeOp() internal view returns (PackedUserOperation memory) {
        bytes memory transferData = abi.encodeWithSelector(TRANSFER_SEL, stranger, 10e6);
        bytes memory callData = abi.encodeWithSelector(EXECUTE_SEL, USDC, 0, transferData);
        return PackedUserOperation({
            sender: agentWallet, nonce: 1, initCode: "",
            callData: callData, accountGasLimits: bytes32(0),
            preVerificationGas: 0, gasFees: bytes32(0),
            paymasterAndData: "", signature: ""
        });
    }

    function test_e2e_registerScopeBlockRevoke() public {
        uint256 scenarioStart = gasleft();

        _step1_register();
        _step2_grantScope();
        _step3_outOfScopeBlocked();
        _step4_emergencyRevoke();

        uint256 totalGas = scenarioStart - gasleft();
        emit log_named_uint("  Total scenario gas", totalGas);
        emit log("========================================");
        emit log("ALL 4 STEPS PASSED");
        emit log("  1. Agent registered on-chain");
        emit log("  2. Restricted scope granted (WETH only)");
        emit log("  3. Out-of-scope Uniswap call BLOCKED");
        emit log("  4. Emergency revoke < 500k gas (~instant)");
        emit log("========================================");
    }
}
