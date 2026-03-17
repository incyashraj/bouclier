// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @dev Well-known addresses and amounts used across all Bouclier unit tests.
contract Constants {
    // ── Test actor keys (deterministic via vm.addr) ──────────────
    uint256 internal constant ENTERPRISE_KEY = 0xA11CE;
    uint256 internal constant AGENT_KEY      = 0xB0B;
    uint256 internal constant STRANGER_KEY   = 0xDEAD;

    // ── Entry point (ERC-4337 v0.7) ───────────────────────────────
    address internal constant ENTRY_POINT = address(0xE7579);

    // ── Token addresses (Base mainnet) ────────────────────────────
    address internal constant USDC  = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address internal constant WETH  = 0x4200000000000000000000000000000000000006;
    address internal constant WBTC  = 0x0555E30da8f98308EdB960aa94C0Db47230d2B9c;

    // ── Chainlink price feed addresses (Base mainnet) ─────────────
    address internal constant ETH_USD_FEED  = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address internal constant USDC_USD_FEED = 0x7E860098F58BBFC8648A4311B374B1d669a2BC9d;

    // ── Common amounts (18-decimal USD) ───────────────────────────
    uint256 internal constant USD_100  = 100e18;
    uint256 internal constant USD_1000 = 1000e18;
    uint256 internal constant USD_1    = 1e18;
    uint256 internal constant USD_50   = 50e18;

    // ── Common selectors ─────────────────────────────────────────
    bytes4 internal constant EXECUTE_SEL  = bytes4(keccak256("execute(address,uint256,bytes)"));
    bytes4 internal constant TRANSFER_SEL = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 internal constant APPROVE_SEL  = bytes4(keccak256("approve(address,uint256)"));
}
