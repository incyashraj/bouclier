// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "../src/RevocationRegistry.sol";
import "../src/AgentRegistry.sol";
import "../src/SpendTracker.sol";
import "../src/AuditLogger.sol";
import "../src/PermissionVault.sol";

/// @title  Bouclier — Arbitrum One Deployment Script
/// @notice Deploys all 5 contracts with Arbitrum-specific Chainlink feeds.
///         Requires ADMIN_ADDRESS as a multisig.
///
/// Usage:
///   forge script script/DeployArbitrum.s.sol \
///     --rpc-url $ARBITRUM_RPC_URL \
///     --broadcast \
///     --verify \
///     --etherscan-api-key $ARBISCAN_API_KEY \
///     --slow
contract DeployArbitrum is Script {

    // Chainlink Arbitrum One feeds
    address constant ETH_USD_FEED  = 0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612; // ETH/USD on Arbitrum
    address constant USDC_ADDRESS  = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831; // USDC (native) Arbitrum
    address constant USDC_USD_FEED = 0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3; // USDC/USD on Arbitrum
    address constant WETH_ADDRESS  = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // WETH on Arbitrum

    function run() external {
        address admin       = vm.envAddress("ADMIN_ADDRESS");
        address ipfsBackend = vm.envAddress("IPFS_BACKEND_ADDRESS");

        require(admin != address(0), "ADMIN_ADDRESS must be set");
        require(admin != msg.sender, "ADMIN_ADDRESS should be a multisig, not the deployer");
        require(ipfsBackend != address(0), "IPFS_BACKEND_ADDRESS must be set");

        console2.log("=== Bouclier Arbitrum Deployment ===");
        console2.log("Chain ID :", block.chainid);
        console2.log("Deployer :", msg.sender);
        console2.log("Admin    :", admin);

        vm.startBroadcast();

        // 1. Deploy
        RevocationRegistry revRegistry = new RevocationRegistry(admin);
        AgentRegistry agentReg         = new AgentRegistry(admin);
        SpendTracker spendTracker      = new SpendTracker(admin);
        AuditLogger auditLogger        = new AuditLogger(admin);
        PermissionVault vault = new PermissionVault(
            admin,
            address(agentReg),
            address(revRegistry),
            address(spendTracker),
            address(auditLogger)
        );

        console2.log("RevocationRegistry:", address(revRegistry));
        console2.log("AgentRegistry     :", address(agentReg));
        console2.log("SpendTracker      :", address(spendTracker));
        console2.log("AuditLogger       :", address(auditLogger));
        console2.log("PermissionVault   :", address(vault));

        // 2. Wire roles
        spendTracker.grantRole(spendTracker.VAULT_ROLE(),   address(vault));
        auditLogger.grantRole(auditLogger.LOGGER_ROLE(),    address(vault));
        revRegistry.grantRole(revRegistry.REVOKER_ROLE(),  address(vault));
        auditLogger.grantRole(auditLogger.IPFS_ROLE(),      ipfsBackend);

        // 3. Set Chainlink Arbitrum price feeds
        spendTracker.setPriceFeed(WETH_ADDRESS, ETH_USD_FEED);
        spendTracker.setPriceFeed(USDC_ADDRESS, USDC_USD_FEED);

        console2.log("--- Price feeds set (ETH/USD, USDC/USD) ---");

        // 4. Revoke deployer admin roles
        spendTracker.revokeRole(spendTracker.DEFAULT_ADMIN_ROLE(), msg.sender);
        auditLogger.revokeRole(auditLogger.DEFAULT_ADMIN_ROLE(),   msg.sender);
        revRegistry.revokeRole(revRegistry.DEFAULT_ADMIN_ROLE(),   msg.sender);

        console2.log("--- Deployer admin roles revoked ---");

        vm.stopBroadcast();

        // 5. Write deployment
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

        string memory line1 = string(abi.encodePacked("{\"chainId\":",              vm.toString(block.chainid),  ","));
        string memory line2 = string(abi.encodePacked("\"deployedAt\":",            vm.toString(block.timestamp), ","));
        string memory line3 = string(abi.encodePacked("\"RevocationRegistry\":\"",  vm.toString(revRegistry),    "\","));
        string memory line4 = string(abi.encodePacked("\"AgentRegistry\":\"",       vm.toString(agentReg),       "\","));
        string memory line5 = string(abi.encodePacked("\"SpendTracker\":\"",        vm.toString(spendTracker),   "\","));
        string memory line6 = string(abi.encodePacked("\"AuditLogger\":\"",         vm.toString(auditLogger),    "\","));
        string memory line7 = string(abi.encodePacked("\"PermissionVault\":\"",     vm.toString(vault),          "\"}"));

        string memory json = string(abi.encodePacked(line1, line2, line3, line4, line5, line6, line7));
        vm.writeFile(path, json);
        console2.log("Deployment addresses written to:", path);
    }
}
