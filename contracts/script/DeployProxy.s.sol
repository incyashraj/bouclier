// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../src/upgradeable/AgentRegistryV1.sol";
import "../src/upgradeable/RevocationRegistryV1.sol";
import "../src/upgradeable/SpendTrackerV1.sol";
import "../src/upgradeable/AuditLoggerV1.sol";
import "../src/upgradeable/PermissionVaultV1.sol";
import "../src/proxy/BouclierProxyAdmin.sol";

/// @title  DeployProxy — UUPS Proxy deployment script (Item 11)
/// @notice Deploys all 4 upgradeable V1 implementations behind ERC1967 UUPS proxies.
///         Note: PermissionVault is complex and should be upgraded last after thorough auditing.
///
/// Usage:
///   forge script script/DeployProxy.s.sol \
///     --rpc-url $BASE_SEPOLIA_RPC_URL \
///     --broadcast \
///     --verify \
///     -vvvv
///
/// After deployment:
///   1. Transfer UPGRADER_ROLE from deployer to proxyAdmin address on each contract
///   2. Add the 3 signer addresses to BouclierProxyAdmin's PROPOSER_ROLE
///   3. To upgrade: proxyAdmin.schedule(...) then wait 48h then proxyAdmin.execute(...)
contract DeployProxy is Script {

    address public admin;
    address public signer1;
    address public signer2;
    address public signer3;

    function run() external {
        admin   = vm.envOr("ADMIN_ADDRESS",   msg.sender);
        signer1 = vm.envOr("SIGNER_1",        msg.sender);
        signer2 = vm.envOr("SIGNER_2",        msg.sender);
        signer3 = vm.envOr("SIGNER_3",        msg.sender);

        console2.log("=== Bouclier UUPS Proxy Deployment ===");
        console2.log("Chain ID :", block.chainid);
        console2.log("Admin    :", admin);

        vm.startBroadcast();

        // ── 1. Deploy BouclierProxyAdmin (2-of-3 multisig timelock) ──
        address[] memory proposers = new address[](3);
        address[] memory executors = new address[](3);
        proposers[0] = signer1; proposers[1] = signer2; proposers[2] = signer3;
        executors[0] = signer1; executors[1] = signer2; executors[2] = signer3;

        BouclierProxyAdmin proxyAdmin = new BouclierProxyAdmin(proposers, executors, admin);
        console2.log("BouclierProxyAdmin :", address(proxyAdmin));

        // ── 2. Deploy RevocationRegistry v1 + proxy ──────────────────
        RevocationRegistryV1 revImpl = new RevocationRegistryV1();
        bytes memory revInit = abi.encodeCall(RevocationRegistryV1.initialize, (admin));
        ERC1967Proxy revProxy = new ERC1967Proxy(address(revImpl), revInit);
        console2.log("RevocationRegistryProxy :", address(revProxy));
        console2.log("RevocationRegistryImpl  :", address(revImpl));

        // ── 3. Deploy AgentRegistry v1 + proxy ───────────────────────
        AgentRegistryV1 agentImpl = new AgentRegistryV1();
        bytes memory agentInit = abi.encodeCall(AgentRegistryV1.initialize, (admin));
        ERC1967Proxy agentProxy = new ERC1967Proxy(address(agentImpl), agentInit);
        console2.log("AgentRegistryProxy :", address(agentProxy));
        console2.log("AgentRegistryImpl  :", address(agentImpl));

        // ── 4. Deploy SpendTracker v1 + proxy ────────────────────────
        SpendTrackerV1 spendImpl = new SpendTrackerV1();
        bytes memory spendInit = abi.encodeCall(SpendTrackerV1.initialize, (admin));
        ERC1967Proxy spendProxy = new ERC1967Proxy(address(spendImpl), spendInit);
        console2.log("SpendTrackerProxy :", address(spendProxy));
        console2.log("SpendTrackerImpl  :", address(spendImpl));

        // ── 5. Deploy AuditLogger v1 + proxy ─────────────────────────
        AuditLoggerV1 auditImpl = new AuditLoggerV1();
        bytes memory auditInit = abi.encodeCall(AuditLoggerV1.initialize, (admin));
        ERC1967Proxy auditProxy = new ERC1967Proxy(address(auditImpl), auditInit);
        console2.log("AuditLoggerProxy :", address(auditProxy));
        console2.log("AuditLoggerImpl  :", address(auditImpl));

        // ── 6. Deploy PermissionVaultV1 + proxy ──────────────────────
        PermissionVaultV1 vaultImpl = new PermissionVaultV1();
        bytes memory vaultInit = abi.encodeCall(
            PermissionVaultV1.initialize,
            (admin, address(agentProxy), address(revProxy), address(spendProxy), address(auditProxy))
        );
        ERC1967Proxy vaultProxy = new ERC1967Proxy(address(vaultImpl), vaultInit);
        console2.log("PermissionVaultProxy :", address(vaultProxy));
        console2.log("PermissionVaultImpl  :", address(vaultImpl));

        // ── 7. Wire roles ─────────────────────────────────────────────
        bytes32 UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
        bytes32 VAULT_ROLE    = keccak256("VAULT_ROLE");
        bytes32 LOGGER_ROLE   = keccak256("LOGGER_ROLE");

        // Grant UPGRADER_ROLE to proxyAdmin on all implementations
        RevocationRegistryV1(address(revProxy)).grantRole(UPGRADER_ROLE, address(proxyAdmin));
        AgentRegistryV1(address(agentProxy)).grantRole(UPGRADER_ROLE, address(proxyAdmin));
        SpendTrackerV1(address(spendProxy)).grantRole(UPGRADER_ROLE, address(proxyAdmin));
        AuditLoggerV1(address(auditProxy)).grantRole(UPGRADER_ROLE, address(proxyAdmin));
        PermissionVaultV1(payable(address(vaultProxy))).grantRole(UPGRADER_ROLE, address(proxyAdmin));

        // Grant VAULT_ROLE on SpendTracker + LOGGER_ROLE on AuditLogger to PermissionVault
        SpendTrackerV1(address(spendProxy)).grantRole(VAULT_ROLE, address(vaultProxy));
        AuditLoggerV1(address(auditProxy)).grantRole(LOGGER_ROLE, address(vaultProxy));

        console2.log("");
        console2.log("=== Deployment complete. Next steps: ===");
        console2.log("1. Revoke UPGRADER_ROLE from deployer on each proxy contract");
        console2.log("2. Verify all proxies on Basescan");
        console2.log("3. Update frontend CONTRACTS config with new proxy addresses");

        vm.stopBroadcast();
    }
}
