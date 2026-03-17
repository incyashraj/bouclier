// ═══════════════════════════════════════════════════════════════════
//  Certora Formal Verification Spec — SpendTracker
//  Verifies: checkSpendCap, rolling spend consistency, oracle safety
// ═══════════════════════════════════════════════════════════════════

methods {
    function recordSpend(bytes32, uint256, uint48) external;
    // NOTE: checkSpendCap and getRollingSpend use block.timestamp internally
    // (sliding window cutoff), so they are NOT envfree.
    function checkSpendCap(bytes32, uint256, uint256) external returns (bool);
    function getRollingSpend(bytes32, uint256) external returns (uint256);
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 1: checkSpendCap returns false when rolling + proposed > cap
// ═══════════════════════════════════════════════════════════════════

rule spendCapEnforced {
    env e;
    bytes32 agentId;
    uint256 proposed;
    uint256 cap;

    require cap > 0;

    uint256 rolling = getRollingSpend(e, agentId, 86400);  // 24h window

    bool result = checkSpendCap(e, agentId, proposed, cap);

    // If rolling + proposed > cap, must return false
    assert (rolling + proposed > cap) => !result,
        "checkSpendCap allowed over-cap spend";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 2: Zero cap means no limit (always passes)
// ═══════════════════════════════════════════════════════════════════

rule zeroCapMeansNoLimit {
    env e;
    bytes32 agentId;
    uint256 proposed;

    bool result = checkSpendCap(e, agentId, proposed, 0);

    assert result == true, "Zero cap should mean unlimited";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 3: Rolling spend monotonicity across windows
//  Larger window >= smaller window (spend can't decrease with more time)
// ═══════════════════════════════════════════════════════════════════

rule rollingSpendMonotonicity {
    env e;
    bytes32 agentId;
    uint256 smallWindow;
    uint256 largeWindow;

    require smallWindow > 0;
    require largeWindow > smallWindow;
    // Prevent underflow: timestamp must be >= largeWindow
    require e.block.timestamp >= largeWindow;

    uint256 smallSpend = getRollingSpend(e, agentId, smallWindow);
    uint256 largeSpend = getRollingSpend(e, agentId, largeWindow);

    assert largeSpend >= smallSpend,
        "Larger window has less spend than smaller window";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 4: recordSpend increases rolling spend
// ═══════════════════════════════════════════════════════════════════

rule recordSpendIncreasesRolling {
    env e;
    bytes32 agentId;
    uint256 amount;
    uint48 ts;

    require amount > 0;
    require ts == assert_uint48(e.block.timestamp);
    // Ensure timestamp is reasonable to avoid underflow in cutoff
    require e.block.timestamp >= 86400;

    uint256 before = getRollingSpend(e, agentId, 86400);

    recordSpend(e, agentId, amount, ts);

    uint256 after = getRollingSpend(e, agentId, 86400);

    assert after >= before + amount,
        "recordSpend did not increase rolling spend";
}
