// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../src/SpendTracker.sol";
import "../../src/interfaces/IBouclier.sol";

/// @title  EchidnaSpendTracker
/// @notice Fuzz properties for SpendTracker ring buffer and spend cap logic.
///         Run: echidna contracts/test/echidna/EchidnaSpendTracker.sol --config contracts/echidna.yaml
contract EchidnaSpendTracker {
    SpendTracker internal tracker;

    bytes32 internal constant AGENT = keccak256("fuzz_agent");

    constructor() {
        tracker = new SpendTracker(address(this));
        tracker.grantRole(tracker.VAULT_ROLE(), address(this));
    }

    // ── Property 1: Rolling spend never exceeds sum of recorded spends ──
    function echidna_rolling_spend_bounded(uint208 amount) public returns (bool) {
        if (amount == 0) return true;

        uint256 before = tracker.getRollingSpend(AGENT, 86400);
        tracker.recordSpend(AGENT, amount, uint48(block.timestamp));
        uint256 after_ = tracker.getRollingSpend(AGENT, 86400);

        return after_ >= before; // rolling spend should never decrease within window
    }

    // ── Property 2: checkSpendCap returns false when cap exceeded ────
    function echidna_cap_check_sound(uint128 cap, uint128 proposed) public view returns (bool) {
        if (cap == 0) return true; // 0 = no cap

        uint256 rolling = tracker.getRollingSpend(AGENT, 86400);
        bool ok = tracker.checkSpendCap(AGENT, proposed, cap);

        if (rolling + uint256(proposed) > uint256(cap)) {
            return !ok; // must return false when over cap
        }
        return true;
    }

    // ── Property 3: Ring buffer never loses most recent entry ────
    function echidna_recent_spend_visible(uint208 amount) public returns (bool) {
        if (amount == 0) return true;

        tracker.recordSpend(AGENT, amount, uint48(block.timestamp));
        uint256 rolling = tracker.getRollingSpend(AGENT, 86400);

        return rolling >= amount; // at minimum, the just-recorded spend is visible
    }
}
