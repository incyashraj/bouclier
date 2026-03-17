// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../helpers/TestBase.sol";
import "../../src/interfaces/IBouclier.sol";

/// @dev Minimal Uniswap V3 SwapRouter interface for testing
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24  fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

/// @title  UniswapIntegration
/// @notice Fork tests demonstrating Bouclier enforcement on real Uniswap V3 swaps.
///         Tests that:
///         1. Permissioned agents CAN swap on allowed protocols
///         2. Agents CANNOT swap on protocols outside their scope
///         3. Spend caps are enforced on real swap values
contract UniswapIntegrationTest is BouclierTestBase {
    // ── Base mainnet addresses ────────────────────────────────────
    address constant UNISWAP_V3_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;
    address constant SUSHISWAP_ROUTER  = 0x6BDED42c6DA8FBf0d2bA55B2fa120C5e0c8D7891;
    address constant BASE_USDC         = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_WETH         = 0x4200000000000000000000000000000000000006;

    // Chainlink ETH/USD on Base
    address constant ETH_USD_FEED_BASE = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

    // ── Fork test setup ──────────────────────────────────────────
    function setUp() public override {
        // Fork Base mainnet
        uint256 forkId = vm.createFork("https://mainnet.base.org");
        vm.selectFork(forkId);

        // Run standard BouclierTestBase setup (deploys all contracts, registers agent)
        super.setUp();

        // Configure Chainlink price feed for WETH
        spendTracker.setPriceFeed(BASE_WETH, ETH_USD_FEED_BASE);
    }

    /// @notice Agent with Uniswap-only scope can execute a swap on Uniswap V3
    function test_agent_can_swap_on_allowed_protocol() public {
        // Grant permission scoped ONLY to Uniswap V3 Router
        address[] memory protocols = new address[](1);
        protocols[0] = UNISWAP_V3_ROUTER;
        bytes4[] memory selectors = new bytes4[](0); // allow all selectors
        address[] memory tokens = new address[](0);

        (PermissionScope memory scope, bytes memory sig) = _buildAndSignScope(
            protocols,
            selectors,
            tokens,
            USD_1000,  // $1000 daily cap
            USD_100,   // $100 per-tx cap
            false,     // NOT allowAnyProtocol — only Uniswap
            true       // allowAnyToken
        );

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Build a UserOp that calls execute(uniswapRouter, 0, swapCalldata)
        bytes memory swapCalldata = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            ISwapRouter.ExactInputSingleParams({
                tokenIn: BASE_WETH,
                tokenOut: BASE_USDC,
                fee: 3000,
                recipient: agentWallet,
                deadline: block.timestamp + 300,
                amountIn: 0.01 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        bytes memory executeCalldata = abi.encodeWithSelector(
            bytes4(0xb61d27f6), // execute(address,uint256,bytes)
            UNISWAP_V3_ROUTER,
            uint256(0),
            swapCalldata
        );

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: agentWallet,
            nonce: 0,
            initCode: "",
            callData: executeCalldata,
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });

        uint256 result = vault.validateUserOp(userOp, keccak256("test-swap"));
        assertEq(result, VALIDATION_SUCCESS, "Agent should be allowed to swap on Uniswap");
    }

    /// @notice Agent with Uniswap-only scope CANNOT swap on SushiSwap
    function test_agent_blocked_on_disallowed_protocol() public {
        // Grant permission scoped ONLY to Uniswap V3 Router
        address[] memory protocols = new address[](1);
        protocols[0] = UNISWAP_V3_ROUTER;
        bytes4[] memory selectors = new bytes4[](0);
        address[] memory tokens = new address[](0);

        (PermissionScope memory scope, bytes memory sig) = _buildAndSignScope(
            protocols,
            selectors,
            tokens,
            USD_1000,
            USD_100,
            false,     // NOT allowAnyProtocol
            true
        );

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Build a UserOp targeting SushiSwap instead of Uniswap
        bytes memory swapCalldata = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            ISwapRouter.ExactInputSingleParams({
                tokenIn: BASE_WETH,
                tokenOut: BASE_USDC,
                fee: 3000,
                recipient: agentWallet,
                deadline: block.timestamp + 300,
                amountIn: 0.01 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );

        bytes memory executeCalldata = abi.encodeWithSelector(
            bytes4(0xb61d27f6),
            SUSHISWAP_ROUTER, // <-- Wrong protocol!
            uint256(0),
            swapCalldata
        );

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: agentWallet,
            nonce: 0,
            initCode: "",
            callData: executeCalldata,
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });

        uint256 result = vault.validateUserOp(userOp, keccak256("test-sushi"));
        assertEq(result, VALIDATION_FAILED, "Agent should be blocked on SushiSwap");
    }

    /// @notice Revoked agent cannot swap even on an allowed protocol
    function test_revoked_agent_blocked_on_swap() public {
        // Grant broad permission
        address[] memory protocols = new address[](1);
        protocols[0] = UNISWAP_V3_ROUTER;
        bytes4[] memory selectors = new bytes4[](0);
        address[] memory tokens = new address[](0);

        (PermissionScope memory scope, bytes memory sig) = _buildAndSignScope(
            protocols,
            selectors,
            tokens,
            USD_1000,
            USD_100,
            false,
            true
        );

        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, sig);

        // Emergency revoke the agent
        vault.emergencyRevoke(agentId);

        // Try to swap — should be blocked
        bytes memory executeCalldata = abi.encodeWithSelector(
            bytes4(0xb61d27f6),
            UNISWAP_V3_ROUTER,
            uint256(0),
            ""
        );

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: agentWallet,
            nonce: 0,
            initCode: "",
            callData: executeCalldata,
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });

        uint256 result = vault.validateUserOp(userOp, keccak256("test-revoked"));
        assertEq(result, VALIDATION_FAILED, "Revoked agent should be blocked");
    }
}
