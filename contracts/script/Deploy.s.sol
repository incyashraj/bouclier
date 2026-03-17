// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "../src/RevocationRegistry.sol";
import "../src/AgentRegistry.sol";
import "../src/SpendTracker.sol";
import "../src/AuditLogger.sol";
import "../src/PermissionVault.sol";

/// @title  Bouclier Protocol — Deployment Script
/// @notice Deploys all 5 contracts in dependency order, wires roles, and writes
///         deployment addresses to script/output/<chainId>.json.
///
/// Usage:
///   forge script script/Deploy.s.sol \
///     --rpc-url $BASE_SEPOLIA_RPC_URL \
///     --broadcast \
///     --verify \
///     -vvvv
contract DeployBouclier is Script {

    // ── Config ────────────────────────────────────────────────────
    // Change these before deploying to a production network
    address public admin;        // protocol admin / multisig
    address public ipfsBackend;  // backend API wallet (gets IPFS_ROLE)

    function run() external {
        admin       = vm.envOr("ADMIN_ADDRESS",        msg.sender);
        ipfsBackend = vm.envOr("IPFS_BACKEND_ADDRESS", msg.sender);

        console2.log("=== Bouclier Deployment ===");
        console2.log("Chain ID :", block.chainid);
        console2.log("Deployer :", msg.sender);
        console2.log("Admin    :", admin);
        console2.log("IPFS API :", ipfsBackend);

        vm.startBroadcast();

        // ── 1. RevocationRegistry ──────────────────────────────────
        RevocationRegistry revRegistry = new RevocationRegistry(admin);
        console2.log("RevocationRegistry:", address(revRegistry));

        // ── 2. AgentRegistry ──────────────────────────────────────
        AgentRegistry agentReg = new AgentRegistry(admin);
        console2.log("AgentRegistry     :", address(agentReg));

        // ── 3. SpendTracker ───────────────────────────────────────
        SpendTracker spendTracker = new SpendTracker(admin);
        console2.log("SpendTracker      :", address(spendTracker));

        // ── 4. AuditLogger ────────────────────────────────────────
        AuditLogger auditLogger = new AuditLogger(admin);
        console2.log("AuditLogger       :", address(auditLogger));

        // ── 5. PermissionVault ────────────────────────────────────
        PermissionVault vault = new PermissionVault(
            admin,
            address(agentReg),
            address(revRegistry),
            address(spendTracker),
            address(auditLogger)
        );
        console2.log("PermissionVault   :", address(vault));

        // ── 6. Wire roles ─────────────────────────────────────────
        // PermissionVault needs VAULT_ROLE on SpendTracker to call recordSpend
        spendTracker.grantRole(spendTracker.VAULT_ROLE(),   address(vault));
        // PermissionVault needs LOGGER_ROLE on AuditLogger to call logAction
        auditLogger.grantRole(auditLogger.LOGGER_ROLE(),    address(vault));
        // PermissionVault needs REVOKER_ROLE on RevocationRegistry for emergencyRevoke
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(),  address(vault));
        // Backend API needs IPFS_ROLE on AuditLogger to call addIPFSCID
        auditLogger.grantRole(auditLogger.IPFS_ROLE(),      ipfsBackend);

        console2.log("--- Roles wired ---");
        console2.log("VAULT_ROLE   -> PermissionVault on SpendTracker");
        console2.log("LOGGER_ROLE  -> PermissionVault on AuditLogger");
        console2.log("REVOKER_ROLE -> PermissionVault on RevocationRegistry");
        console2.log("IPFS_ROLE    -> Backend API on AuditLogger");

        // ── 7. Revoke deployer roles if admin != msg.sender ───────
        // If a multisig is used as admin, revoke the deployer's admin role
        // to ensure the deployer cannot act without multisig consensus.
        if (admin != msg.sender) {
            spendTracker.revokeRole(spendTracker.DEFAULT_ADMIN_ROLE(), msg.sender);
            auditLogger.revokeRole(auditLogger.DEFAULT_ADMIN_ROLE(),   msg.sender);
            revRegistry.revokeRole(revRegistry.DEFAULT_ADMIN_ROLE(),   msg.sender);
            agentReg.pause(); // pause only — agentReg is Pausable with admin=admin
            console2.log("--- Deployer admin roles revoked (multisig admin detected) ---");
        }

        vm.stopBroadcast();

        // ── 8. Write addresses to file ───────────────────────────
        _writeDeployment(
            address(revRegistry),
            address(agentReg),
            address(spendTracker),
            address(auditLogger),
            address(vault)
        );
    }

    function _writeDeployment(
        address revRegistry,
        address agentReg,
        address spendTracker,
        address auditLogger,
        address vault
    ) internal {
        string memory path = string(abi.encodePacked(
            "script/output/", vm.toString(block.chainid), ".json"
        ));

        // Build JSON incrementally to avoid stack-too-deep
        string memory line1 = string(abi.encodePacked("{\"chainId\":",           vm.toString(block.chainid), ","));
        string memory line2 = string(abi.encodePacked("\"deployedAt\":",         vm.toString(block.timestamp), ","));
        string memory line3 = string(abi.encodePacked("\"RevocationRegistry\":\"", vm.toString(revRegistry), "\","));
        string memory line4 = string(abi.encodePacked("\"AgentRegistry\":\"",    vm.toString(agentReg),    "\","));
        string memory line5 = string(abi.encodePacked("\"SpendTracker\":\"",     vm.toString(spendTracker), "\","));
        string memory line6 = string(abi.encodePacked("\"AuditLogger\":\"",      vm.toString(auditLogger),  "\","));
        string memory line7 = string(abi.encodePacked("\"PermissionVault\":\"",  vm.toString(vault),        "\"}"));

        string memory json = string(abi.encodePacked(line1, line2, line3, line4, line5, line6, line7));
        vm.writeFile(path, json);
        console2.log("Deployment addresses written to:", path);
    }
}
