// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "./Constants.sol";

import "../../src/RevocationRegistry.sol";
import "../../src/AgentRegistry.sol";
import "../../src/SpendTracker.sol";
import "../../src/AuditLogger.sol";
import "../../src/PermissionVault.sol";
import "../../src/interfaces/IBouclier.sol";

/// @dev Shared test base: deploys all five Bouclier contracts with full role wiring.
///      All unit test files inherit from this.
abstract contract BouclierTestBase is Test, Constants {
    // ── Contracts ─────────────────────────────────────────────────
    RevocationRegistry internal revRegistry;
    AgentRegistry      internal agentReg;
    SpendTracker       internal spendTracker;
    AuditLogger        internal auditLogger;
    PermissionVault    internal vault;

    // ── Actors (deterministic) ────────────────────────────────────
    address internal enterprise;    // owner account
    address internal agentWallet;   // the smart-account controlled by agent
    address internal stranger;      // has no permissions
    address internal admin;         // protocol admin (== address(this) in tests)

    // ── Registered agent ─────────────────────────────────────────
    bytes32 internal agentId;

    function setUp() public virtual {
        // Start at a timestamp safely beyond any rolling windows (> 24h)
        vm.warp(7 days);

        // Derive test addresses from keys
        enterprise  = vm.addr(ENTERPRISE_KEY);
        agentWallet = vm.addr(AGENT_KEY);
        stranger    = vm.addr(STRANGER_KEY);
        admin       = address(this);

        // 1. Deploy independent contracts (admin = address(this))
        revRegistry  = new RevocationRegistry(admin);
        agentReg     = new AgentRegistry(admin);
        spendTracker = new SpendTracker(admin);
        auditLogger  = new AuditLogger(admin);

        // 2. Deploy PermissionVault — wires all dependencies
        vault = new PermissionVault(
            admin,
            address(agentReg),
            address(revRegistry),
            address(spendTracker),
            address(auditLogger)
        );

        // 3. Grant operational roles to PermissionVault
        spendTracker.grantRole(spendTracker.VAULT_ROLE(),      address(vault));
        auditLogger.grantRole(auditLogger.LOGGER_ROLE(),       address(vault));
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(),      address(vault));

        // 4. Register a default agent for tests that need one
        vm.prank(enterprise);
        agentId = agentReg.register(agentWallet, "gpt-4o", bytes32(0), "QmTestCID");
    }

    // ── Helpers ───────────────────────────────────────────────────

    /// @dev Build a signed PermissionScope grant. Uses ENTERPRISE_KEY to sign.
    function _buildAndSignScope(
        address[] memory protocols,
        bytes4[]  memory selectors,
        address[] memory tokens,
        uint256 dailyCap,
        uint256 perTxCap,
        bool anyProtocol,
        bool anyToken
    ) internal view returns (PermissionScope memory scope, bytes memory sig) {
        scope = PermissionScope({
            agentId:           agentId,
            allowedProtocols:  protocols,
            allowedSelectors:  selectors,
            allowedTokens:     tokens,
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
        sig = _signScope(scope, ENTERPRISE_KEY);
    }

    /// @dev Low-level EIP-712 scope signer.
    function _signScope(PermissionScope memory scope, uint256 signerKey)
        internal view returns (bytes memory)
    {
        // Must match PermissionVault.grantPermission structHash encoding exactly:
        // (SCOPE_TYPEHASH, agentId, nonce, dailyCap, perTxCap, validFrom, validUntil, anyProtocol, anyToken)
        bytes32 structHash = keccak256(abi.encode(
            vault.SCOPE_TYPEHASH(),
            scope.agentId,
            vault.grantNonces(scope.agentId),          // nonce comes second
            scope.dailySpendCapUSD,
            scope.perTxSpendCapUSD,
            scope.validFrom,
            scope.validUntil,
            scope.allowAnyProtocol,
            scope.allowAnyToken
        ));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerKey, digest);
        return abi.encodePacked(r, s, v);
    }

    /// @dev Build a UserOp that calls execute(target, value, data) on agentWallet.
    function _buildUserOp(
        address target,
        uint256 value,
        bytes memory innerData
    ) internal view returns (PackedUserOperation memory op) {
        bytes memory callData = abi.encodeWithSelector(
            EXECUTE_SEL, target, value, innerData
        );
        op = PackedUserOperation({
            sender:             agentWallet,
            nonce:              0,
            initCode:           "",
            callData:           callData,
            accountGasLimits:   bytes32(0),
            preVerificationGas: 0,
            gasFees:            bytes32(0),
            paymasterAndData:   "",
            signature:          ""           // filled by caller if needed
        });
    }

    /// @dev Grant a default permissive scope for agentId (allowAny + large caps).
    function _grantDefaultScope() internal {
        address[] memory noList = new address[](0);
        bytes4[]  memory noSel  = new bytes4[](0);
        (PermissionScope memory scope, bytes memory sig) =
            _buildAndSignScope(noList, noSel, noList, USD_1000, USD_100, true, true);

        vm.prank(enterprise);
        vault.grantPermission(scope.agentId, scope, sig);
    }
}
