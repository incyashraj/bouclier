// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import "../src/RevocationRegistry.sol";
import "../src/AgentRegistry.sol";
import "../src/SpendTracker.sol";
import "../src/AuditLogger.sol";
import "../src/PermissionVault.sol";

/// @title  Bouclier — Mainnet Deployment Script
/// @notice Same as Deploy.s.sol but with mainnet safety checks:
///         - Requires explicit ADMIN_ADDRESS (no fallback to deployer)
///         - Requires 2-of-3 multisig as admin
///         - Revokes deployer admin role after wiring
///         - Sets Chainlink mainnet price feeds for SpendTracker
///
/// Usage:
///   # Dry run first — always simulate before mainnet
///   forge script script/DeployMainnet.s.sol \
///     --rpc-url $BASE_MAINNET_RPC_URL \
///     --simulate
///
///   # Real deployment
///   forge script script/DeployMainnet.s.sol \
///     --rpc-url $BASE_MAINNET_RPC_URL \
///     --private-key $DEPLOYER_PRIVATE_KEY \
///     --broadcast \
///     --verify \
///     --etherscan-api-key $BASESCAN_API_KEY \
///     --slow
contract DeployMainnet is Script {

    // Chainlink Base Mainnet feeds
    address constant ETH_USD_FEED  = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70; // ETH/USD on Base
    address constant USDC_ADDRESS  = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC Base mainnet
    address constant USDC_USD_FEED = 0x7e860098F58bBFC8648a4311b374B1D669a2bc6B; // USDC/USD on Base
    address constant WETH_ADDRESS  = 0x4200000000000000000000000000000000000006; // WETH Base mainnet

    function run() external {
        // MAINNET SAFETY: admin MUST be explicitly set (no fallback to deployer)
        address admin       = vm.envAddress("ADMIN_ADDRESS");
        address ipfsBackend = vm.envAddress("IPFS_BACKEND_ADDRESS");

        require(admin != address(0), "ADMIN_ADDRESS must be set for mainnet");
        require(admin != msg.sender, "ADMIN_ADDRESS should be a multisig, not the deployer");
        require(ipfsBackend != address(0), "IPFS_BACKEND_ADDRESS must be set");

        console2.log("=== Bouclier Mainnet Deployment ===");
        console2.log("Chain ID :", block.chainid);
        console2.log("Deployer :", msg.sender);
        console2.log("Admin (multisig):", admin);
        console2.log("IPFS Backend    :", ipfsBackend);

        vm.startBroadcast();

        // 1. Deploy all contracts
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

        // 3. Set Chainlink mainnet price feeds
        spendTracker.setPriceFeed(WETH_ADDRESS, ETH_USD_FEED);
        spendTracker.setPriceFeed(USDC_ADDRESS, USDC_USD_FEED);

        console2.log("--- Price feeds set (ETH/USD, USDC/USD) ---");

        // 4. Revoke deployer admin roles — admin is now solely the multisig
        spendTracker.revokeRole(spendTracker.DEFAULT_ADMIN_ROLE(), msg.sender);
        auditLogger.revokeRole(auditLogger.DEFAULT_ADMIN_ROLE(),   msg.sender);
        revRegistry.revokeRole(revRegistry.DEFAULT_ADMIN_ROLE(),   msg.sender);

        console2.log("--- Deployer admin roles revoked. Multisig is sole admin. ---");

        vm.stopBroadcast();

        // 5. Write deployment addresses
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
