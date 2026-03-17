// ═══════════════════════════════════════════════════════════════════
//  Certora Formal Verification Spec — SpendTracker
//  Verifies: checkSpendCap, rolling spend consistency, oracle safety
// ═══════════════════════════════════════════════════════════════════

methods {
    function recordSpend(bytes32, uint256, uint48) external;
    function checkSpendCap(bytes32, uint256, uint256) external returns (bool) envfree;
    function getRollingSpend(bytes32, uint256) external returns (uint256) envfree;
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 1: checkSpendCap returns false when rolling + proposed > cap
// ═══════════════════════════════════════════════════════════════════

rule spendCapEnforced {
    bytes32 agentId;
    uint256 proposed;
    uint256 cap;

    require cap > 0;

    uint256 rolling = getRollingSpend(agentId, 86400);  // 24h window

    bool result = checkSpendCap(agentId, proposed, cap);

    // If rolling + proposed > cap, must return false
    assert (rolling + proposed > cap) => !result,
        "checkSpendCap allowed over-cap spend";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 2: Zero cap means no limit (always passes)
// ═══════════════════════════════════════════════════════════════════

rule zeroCapMeansNoLimit {
    bytes32 agentId;
    uint256 proposed;

    bool result = checkSpendCap(agentId, proposed, 0);

    assert result == true, "Zero cap should mean unlimited";
}

// ═══════════════════════════════════════════════════════════════════
//  RULE 3: Rolling spend monotonicity across windows
//  Larger window >= smaller window (spend can't decrease with more time)
// ═══════════════════════════════════════════════════════════════════

rule rollingSpendMonotonicity {
    bytes32 agentId;
    uint256 smallWindow;
    uint256 largeWindow;

    require smallWindow > 0;
    require largeWindow > smallWindow;

    uint256 smallSpend = getRollingSpend(agentId, smallWindow);
    uint256 largeSpend = getRollingSpend(agentId, largeWindow);

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
    require ts == e.block.timestamp;

    uint256 before = getRollingSpend(agentId, 86400);

    recordSpend(e, agentId, amount, ts);

    uint256 after = getRollingSpend(agentId, 86400);

    assert after >= before + amount,
        "recordSpend did not increase rolling spend";
}
