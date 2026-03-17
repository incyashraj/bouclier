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

// ── Minimal mock Chainlink aggregator ──────────────────────────────────────────
/// @dev Returns a configurable answer. Matches the pattern from unit tests.
contract MockFeedIntegration {
    int256  public answer;
    uint8   public decimals;
    uint256 public updatedAt;

    constructor(int256 _answer, uint8 _decimals) {
        answer   = _answer;
        decimals = _decimals;
        updatedAt = block.timestamp;
    }

    function setAnswer(int256 _answer) external { answer = _answer; updatedAt = block.timestamp; }

    function latestRoundData()
        external
        view
        returns (uint80, int256, uint256, uint256, uint80)
    {
        return (1, answer, block.timestamp, updatedAt, 1);
    }
}

/// @title  PermissionVault Integration Tests
/// @notice Tests the full end-to-end validation pipeline:
///         deploy all 5 contracts → register agent → grant scope → submit UserOp.
///
///         All 4 scenarios from the Phase 1 success criterion are covered:
///           1. Agent swap within scope                       → VALIDATION_SUCCESS
///           2. Agent swap exceeding daily spend cap          → VALIDATION_FAILED
///           3. Agent targeting a disallowed protocol         → VALIDATION_FAILED
///           4. Revoked agent attempting any action           → VALIDATION_FAILED
///
///         A 5th test exercises the circuit with a Base mainnet fork when
///         BASE_MAINNET_RPC_URL is present in the environment.
contract PermissionVaultIntegrationTest is Test, Constants {

    // ── Contracts ──────────────────────────────────────────────────────────────
    RevocationRegistry internal revRegistry;
    AgentRegistry      internal agentReg;
    SpendTracker       internal spendTracker;
    AuditLogger        internal auditLogger;
    PermissionVault    internal vault;

    // ── Mock oracle ────────────────────────────────────────────────────────────
    MockFeedIntegration internal usdcFeed;

    // ── Actors ────────────────────────────────────────────────────────────────
    address internal owner;           // agent owner (enterprise wallet)
    address internal agentWallet;     // smart-account address of the AI agent
    address internal stranger;        // uninvolved address (used as transfer recipient)
    address internal admin;           // protocol admin

    // ── Agent state ────────────────────────────────────────────────────────────
    bytes32 internal agentId;

    // ── Uniswap v3 SwapRouter02 (Base mainnet) ─────────────────────────────────
    address internal constant UNISWAP_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;
    bytes4  internal constant EXACT_INPUT_SEL    = bytes4(keccak256("exactInputSingle((address,address,uint24,address,uint256,uint256,uint160))"));

    // ── Setup ──────────────────────────────────────────────────────────────────

    function setUp() public virtual {
        vm.warp(7 days); // avoid rolling-window underflow

        owner       = vm.addr(ENTERPRISE_KEY);
        agentWallet = vm.addr(AGENT_KEY);
        stranger    = vm.addr(STRANGER_KEY);
        admin       = address(this);

        // 1. Deploy mock USDC/USD Chainlink feed (1 USDC = $1.0000; 8-decimal feed)
        usdcFeed = new MockFeedIntegration(1e8, 8);

        // 2. Deploy all five Bouclier contracts
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

        // 3. Wire operational roles
        spendTracker.grantRole(spendTracker.VAULT_ROLE(),  address(vault));
        auditLogger.grantRole(auditLogger.LOGGER_ROLE(),   address(vault));
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(),  address(vault));

        // 4. Register USDC price feed (Base mainnet USDC address)
        spendTracker.setPriceFeed(USDC, address(usdcFeed));

        // 5. Register the AI agent
        vm.prank(owner);
        agentId = agentReg.register(agentWallet, "claude-3-5-sonnet", bytes32(0), "QmIntegrationCID");
    }

    // ── Helper: grant a scope to the test agent ────────────────────────────────

    function _grantScope(
        address[] memory allowedProtocols,
        bool anyProtocol,
        bool anyToken,
        uint256 dailyCap,
        uint256 perTxCap
    ) internal {
        PermissionScope memory scope = PermissionScope({
            agentId:           agentId,
            allowedProtocols:  allowedProtocols,
            allowedSelectors:  new bytes4[](0),
            allowedTokens:     new address[](0),
            dailySpendCapUSD:  dailyCap,
            perTxSpendCapUSD:  perTxCap,
            validFrom:         uint48(block.timestamp),
            validUntil:        uint48(block.timestamp + 30 days),
            allowAnyProtocol:  anyProtocol,
            allowAnyToken:     anyToken,
            revoked:           false,
            grantHash:         bytes32(0),
            windowStartHour:   0,
            windowEndHour:     0,
            windowDaysMask:    0,
            allowedChainId:    0
        });

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
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ENTERPRISE_KEY, digest);
        bytes memory sig = abi.encodePacked(r, s, v);

        vm.prank(owner);
        vault.grantPermission(agentId, scope, sig);
    }

    /// @dev Build a UserOp that calls `target.execute(to, value, data)`.
    ///      The outer selector is the standard ERC-4337 0xb61d27f6 execute selector.
    function _buildTransferOp(
        address tokenContract,
        address recipient,
        uint256 amount
    ) internal view returns (PackedUserOperation memory op) {
        // Inner call: ERC-20 transfer(address,uint256)
        bytes memory innerData = abi.encodeWithSelector(TRANSFER_SEL, recipient, amount);
        // Outer call: execute(address,uint256,bytes)
        bytes memory callData  = abi.encodeWithSelector(EXECUTE_SEL, tokenContract, 0, innerData);

        op = PackedUserOperation({
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
    }

    /// @dev Build a UserOp that calls an arbitrary protocol (e.g. Uniswap).
    function _buildProtocolOp(
        address protocol,
        bytes4  sel
    ) internal view returns (PackedUserOperation memory op) {
        bytes memory innerData = abi.encodePacked(sel, new bytes(64)); // minimal callbytes
        bytes memory callData  = abi.encodeWithSelector(EXECUTE_SEL, protocol, 0, innerData);
        op = PackedUserOperation({
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
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 1 — within-scope USDC transfer → VALIDATION_SUCCESS
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Agent sends 50 USDC to a recipient.
    ///         Scope: anyProtocol, anyToken, perTx=$100, daily=$1000.
    ///         Oracle: 1 USDC = $1. USD value = $50 ← passes all caps.
    function test_integration_withinScope_passes() public {
        _grantScope(new address[](0), true, true, USD_1000, USD_100);

        // 50 USDC (raw: 50 * 1e6 since USDC is 6-decimal)
        PackedUserOperation memory op = _buildTransferOp(USDC, stranger, 50e6);
        bytes32 opHash = keccak256(abi.encode(op));

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, opHash);

        assertEq(result, VALIDATION_SUCCESS, "within-scope op should pass");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 2 — daily cap exceeded → VALIDATION_FAILED
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Agent submits two $60 USDC transfers.
    ///         Scope: daily=$100. First succeeds ($60 <= $100). Second fails ($120 > $100).
    function test_integration_dailyCapExceeded_fails() public {
        _grantScope(new address[](0), true, true, USD_100, USD_1000);

        PackedUserOperation memory op1 = _buildTransferOp(USDC, stranger, 60e6); // $60
        PackedUserOperation memory op2 = _buildTransferOp(USDC, stranger, 60e6); // $60 again

        vm.prank(ENTRY_POINT);
        assertEq(vault.validateUserOp(op1, keccak256(abi.encode(op1))), VALIDATION_SUCCESS,
            "first $60 tx should pass");

        vm.prank(ENTRY_POINT);
        uint256 result2 = vault.validateUserOp(op2, keccak256(abi.encode(op2)));
        assertEq(result2, VALIDATION_FAILED, "second $60 tx should exceed daily cap");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 3 — disallowed protocol → VALIDATION_FAILED
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Scope only allows calls to WETH contract.
    ///         Agent tries to call Uniswap Router → PROTOCOL_NOT_ALLOWED.
    function test_integration_disallowedProtocol_fails() public {
        // Scope: allowedProtocols = [WETH only]
        address[] memory allowedProtos = new address[](1);
        allowedProtos[0] = WETH;
        _grantScope(allowedProtos, false, true, USD_1000, USD_100);

        // UserOp targets Uniswap Router (not in allowlist)
        PackedUserOperation memory op = _buildProtocolOp(UNISWAP_ROUTER, EXACT_INPUT_SEL);
        bytes32 opHash = keccak256(abi.encode(op));

        vm.expectEmit(false, false, false, false);
        emit IPermissionVault.PermissionViolation(agentId, UNISWAP_ROUTER, EXACT_INPUT_SEL, "PROTOCOL_NOT_ALLOWED");

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, opHash);
        assertEq(result, VALIDATION_FAILED, "disallowed protocol should fail");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 4 — revoked agent → VALIDATION_FAILED
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Revoke the agent in RevocationRegistry.
    ///         Any subsequent UserOp should immediately fail with AGENT_REVOKED.
    function test_integration_revokedAgent_fails() public {
        _grantScope(new address[](0), true, true, USD_1000, USD_100);

        // Revoke via owner using PermissionVault.emergencyRevoke (which also writes RevocationRegistry)
        vm.prank(owner);
        vault.emergencyRevoke(agentId);

        PackedUserOperation memory op = _buildTransferOp(USDC, stranger, 10e6); // $10

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, keccak256(abi.encode(op)));
        assertEq(result, VALIDATION_FAILED, "revoked agent should be blocked");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 5 — per-tx cap exceeded → VALIDATION_FAILED
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Scope: perTx=$10, daily=$1000.
    ///         Agent submits a single $50 USDC transfer → blocked by per-tx cap.
    function test_integration_perTxCapExceeded_fails() public {
        _grantScope(new address[](0), true, true, USD_1000, 10e18 /* $10 */);

        PackedUserOperation memory op = _buildTransferOp(USDC, stranger, 50e6); // $50
        bytes32 opHash = keccak256(abi.encode(op));

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, opHash);
        assertEq(result, VALIDATION_FAILED, "tx exceeding per-tx cap should fail");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 6 — no active scope → VALIDATION_FAILED
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Agent is registered but has never been granted a scope.
    function test_integration_noScope_fails() public {
        // No _grantScope() call — agent has no scope
        PackedUserOperation memory op = _buildTransferOp(USDC, stranger, 10e6);

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, keccak256(abi.encode(op)));
        assertEq(result, VALIDATION_FAILED, "agent with no scope should fail");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Scenario 7 — scope expired → VALIDATION_FAILED
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Grant a scope with a 1-day validUntil, then advance time past it.
    function test_integration_expiredScope_fails() public {
        _grantScope(new address[](0), true, true, USD_1000, USD_100);

        // Advance 31 days — scope validUntil = now + 30 days
        vm.warp(block.timestamp + 31 days);

        PackedUserOperation memory op = _buildTransferOp(USDC, stranger, 10e6);

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, keccak256(abi.encode(op)));
        assertEq(result, VALIDATION_FAILED, "expired scope should fail");
    }

    // ══════════════════════════════════════════════════════════════════════════════
    // Fork test — real Base mainnet Chainlink feeds (requires BASE_MAINNET_RPC_URL)
    // ══════════════════════════════════════════════════════════════════════════════

    /// @notice Fork Base mainnet, replace the USDC oracle with the real Chainlink feed,
    ///         and verify that a $50 USDC transfer is accepted at live market prices.
    ///
    ///         Run with:
    ///           BASE_MAINNET_RPC_URL=<url> forge test --match-test test_fork_realChainlink -vvvv
    function test_fork_realChainlink() public {
        string memory rpcUrl = vm.envOr("BASE_MAINNET_RPC_URL", string(""));
        vm.skip(bytes(rpcUrl).length == 0); // skip if no fork URL configured

        // Fork at latest block — Chainlink feeds should be fresh (<1h old)
        vm.createSelectFork(rpcUrl);
        vm.warp(block.timestamp); // no-op; ensures block.timestamp is fork timestamp

        // Re-deploy all contracts on the fork
        setUp();

        // Replace mock feed with real Base mainnet USDC/USD Chainlink feed
        spendTracker.setPriceFeed(USDC, USDC_USD_FEED);

        // Grant scope: anyProtocol, anyToken, $100 perTx, $1000 daily
        _grantScope(new address[](0), true, true, USD_1000, USD_100);

        // 50 USDC — should be ~$50 at live price
        PackedUserOperation memory op = _buildTransferOp(USDC, stranger, 50e6);

        vm.prank(ENTRY_POINT);
        uint256 result = vault.validateUserOp(op, keccak256(abi.encode(op)));
        assertEq(result, VALIDATION_SUCCESS, "live oracle: 50 USDC within $100 per-tx cap should pass");
    }
}
