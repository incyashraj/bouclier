// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "../src/AgentRegistry.sol";

/// @title  Bouclier — Ethereum Mainnet Registry-Only Deployment
/// @notice Deploys ONLY the AgentRegistry on Ethereum L1 as an identity anchor.
///         The remaining contracts (PermissionVault, SpendTracker, AuditLogger,
///         RevocationRegistry) live on L2 (Base / Arbitrum) where gas is cheap.
///
/// Usage:
///   forge script script/DeployRegistryOnly.s.sol \
///     --rpc-url $ETH_MAINNET_RPC_URL \
///     --broadcast \
///     --verify \
///     -vvvv
contract DeployRegistryOnly is Script {

    address public admin;

    function run() external {
        admin = vm.envOr("ADMIN_ADDRESS", msg.sender);

        console2.log("=== Bouclier Registry-Only Deployment (Ethereum Mainnet) ===");
        console2.log("Chain ID :", block.chainid);
        console2.log("Deployer :", msg.sender);
        console2.log("Admin    :", admin);

        vm.startBroadcast();

        AgentRegistry agentReg = new AgentRegistry(admin);
        console2.log("AgentRegistry:", address(agentReg));

        // Transfer admin to multisig if different from deployer
        if (admin != msg.sender) {
            console2.log("--- Deployer admin role retained for now (transfer via multisig) ---");
        }

        vm.stopBroadcast();

        // Write deployment output
        string memory path = string(abi.encodePacked(
            "script/output/", vm.toString(block.chainid), ".json"
        ));
        string memory json = string(abi.encodePacked(
            "{\"chainId\":", vm.toString(block.chainid), ",",
            "\"deployedAt\":", vm.toString(block.timestamp), ",",
            "\"AgentRegistry\":\"", vm.toString(address(agentReg)), "\"}"
        ));
        vm.writeFile(path, json);
        console2.log("Deployment written to:", path);
    }
}
