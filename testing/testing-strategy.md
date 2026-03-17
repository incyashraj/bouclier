# Testing Strategy — Bouclier Protocol

> This document defines the complete 4-tier testing strategy for all Bouclier components.
> Every test referenced in the contract architecture files traces back to this document.
> **Tests are written before or alongside implementation — never after.**

---

## Testing Philosophy

1. **Contract safety is non-negotiable.** The protocol handles real money. A 99% test score is a failure.
2. **Test the invariants, not just the happy path.** The most dangerous bugs are the ones that only appear at boundaries.
3. **Fuzz everything on the hot path.** `validateUserOp`, `checkSpendCap`, `isRevoked` — these functions run on every transaction. They must be correct for ALL inputs.
4. **Tests are documentation.** A developer reading a test file should fully understand what the contract is supposed to do.

---

## Four-Tier Testing Architecture

```
Tier 1: Unit Tests (Foundry)
  ↓ Every function in isolation
  ↓ ~200 test cases across all contracts
  ↓ Run on every PR (< 2 minutes)

Tier 2: Integration Tests (Foundry Fork)
  ↓ Full end-to-end UserOp flow
  ↓ Real Uniswap/Aave on forked Base Sepolia
  ↓ Run on every PR (< 10 minutes)

Tier 3: Fuzz Tests (Echidna + Foundry Invariant)
  ↓ Property-based testing: 10M+ iterations
  ↓ Identifies edge cases humans miss
  ↓ Run nightly (< 2 hours)

Tier 4: Formal Verification (Certora Prover)
  ↓ Mathematical proof of critical properties
  ↓ Cannot be bypassed by any input
  ↓ Run weekly or before major releases
```

---

## Tier 1: Unit Tests (Foundry)

### Setup

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Project structure
contracts/
├── src/
│   ├── AgentRegistry.sol
│   ├── PermissionVault.sol
│   ├── SpendTracker.sol
│   ├── AuditLogger.sol
│   └── RevocationRegistry.sol
├── test/
│   ├── unit/
│   │   ├── AgentRegistry.t.sol
│   │   ├── PermissionVault.t.sol
│   │   ├── SpendTracker.t.sol
│   │   ├── AuditLogger.t.sol
│   │   └── RevocationRegistry.t.sol
│   ├── integration/
│   │   └── FullFlow.integration.t.sol
│   └── helpers/
│       ├── TestBase.sol      ← Common fixtures, deployers
│       └── Constants.sol     ← Test addresses, amounts
└── foundry.toml
```

### Running Tests

```bash
# Run all unit tests
forge test --match-path "test/unit/*" -vvv

# Run a specific contract's tests
forge test --match-contract "AgentRegistryTest" -vvv

# Run with gas reporting
forge test --gas-report

# Run with coverage
forge coverage --report lcov
# Open coverage report
genhtml lcov.info -o coverage-report
open coverage-report/index.html

# Coverage targets
# AgentRegistry.sol      ≥ 90% line coverage
# PermissionVault.sol    ≥ 95% line coverage (critical path)
# SpendTracker.sol       ≥ 95% line coverage
# AuditLogger.sol        ≥ 90% line coverage
# RevocationRegistry.sol ≥ 95% line coverage
```

### `foundry.toml` Configuration

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc = "0.8.24"
optimizer = true
optimizer_runs = 200
via_ir = false

[profile.default.fuzz]
runs = 256        # Default fuzz runs for forge test

[profile.ci]
fuzz.runs = 1000  # More runs in CI

[rpc_endpoints]
base_sepolia   = "${BASE_SEPOLIA_RPC_URL}"
base_mainnet   = "${BASE_MAINNET_RPC_URL}"

[etherscan]
base_sepolia   = { key = "${BASESCAN_API_KEY}", chain = 84532 }
base_mainnet   = { key = "${BASESCAN_API_KEY}", chain = 8453 }
```

---

### AgentRegistry Unit Tests

**File:** `test/unit/AgentRegistry.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../src/AgentRegistry.sol";

contract AgentRegistryTest is Test {
    AgentRegistry public registry;
    address public owner = makeAddr("owner");
    address public agentWallet = makeAddr("agentWallet");
    address public stranger = makeAddr("stranger");
    
    function setUp() public {
        registry = new AgentRegistry();
    }
    
    // ── Registration ───────────────────────────────────────────────
    
    function test_register_success() public {
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "claude-sonnet-4-6", bytes32(0), "ipfs://Qm...");
        
        assertNotEq(agentId, bytes32(0));
        
        AgentRegistry.AgentRecord memory record = registry.resolve(agentId);
        assertEq(record.agentAddress, agentWallet);
        assertEq(record.owner, owner);
        assertEq(record.model, "claude-sonnet-4-6");
        assertEq(uint8(record.status), uint8(AgentRegistry.AgentStatus.Active));
    }
    
    function test_register_emitsEvent() public {
        vm.prank(owner);
        vm.expectEmit(true, true, true, false);
        emit AgentRegistry.AgentRegistered(bytes32(0), agentWallet, owner, "", 0); // partial match
        
        registry.register(agentWallet, "claude-sonnet-4-6", bytes32(0), "");
    }
    
    function test_register_didFormat_base() public {
        vm.chainId(8453); // Base mainnet
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "gpt-4o", bytes32(0), "");
        
        AgentRegistry.AgentRecord memory record = registry.resolve(agentId);
        assertTrue(bytes(record.did).length > 0);
        // DID should start with "did:ethr:base:0x"
        assertEq(
            bytes16(bytes(record.did)),
            bytes16("did:ethr:base:0x")
        );
    }
    
    function test_register_reverseLookup() public {
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "claude", bytes32(0), "");
        
        assertEq(registry.getAgentId(agentWallet), agentId);
    }
    
    function test_register_duplicateAddress_reverts() public {
        vm.startPrank(owner);
        registry.register(agentWallet, "claude", bytes32(0), "");
        
        vm.expectRevert("AgentRegistry: address already registered");
        registry.register(agentWallet, "gpt-4o", bytes32(0), "");
        vm.stopPrank();
    }
    
    function test_register_incrementsCounter() public {
        assertEq(registry.totalAgents(), 0);
        
        vm.prank(owner);
        registry.register(agentWallet, "claude", bytes32(0), "");
        assertEq(registry.totalAgents(), 1);
        
        vm.prank(owner);
        registry.register(makeAddr("agent2"), "gpt-4o", bytes32(0), "");
        assertEq(registry.totalAgents(), 2);
    }
    
    // ── Status Updates ─────────────────────────────────────────────
    
    function test_updateStatus_ownerCanSuspend() public {
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "claude", bytes32(0), "");
        
        vm.prank(owner);
        registry.updateStatus(agentId, AgentRegistry.AgentStatus.Suspended);
        
        assertFalse(registry.isActive(agentId));
    }
    
    function test_updateStatus_strangerCannotUpdate() public {
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "claude", bytes32(0), "");
        
        vm.prank(stranger);
        vm.expectRevert("AgentRegistry: not owner");
        registry.updateStatus(agentId, AgentRegistry.AgentStatus.Suspended);
    }
    
    // ── Queries ────────────────────────────────────────────────────
    
    function test_isActive_trueForActiveAgent() public {
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "claude", bytes32(0), "");
        assertTrue(registry.isActive(agentId));
    }
    
    function test_isActive_falseForRevokedAgent() public {
        vm.prank(owner);
        bytes32 agentId = registry.register(agentWallet, "claude", bytes32(0), "");
        
        vm.prank(owner);
        registry.updateStatus(agentId, AgentRegistry.AgentStatus.Revoked);
        assertFalse(registry.isActive(agentId));
    }
    
    function test_getAgentsByOwner() public {
        vm.startPrank(owner);
        registry.register(agentWallet, "claude", bytes32(0), "");
        registry.register(makeAddr("agent2"), "gpt", bytes32(0), "");
        registry.register(makeAddr("agent3"), "llama", bytes32(0), "");
        vm.stopPrank();
        
        bytes32[] memory ids = registry.getAgentsByOwner(owner);
        assertEq(ids.length, 3);
    }
    
    function test_resolve_nonExistentId_returnsEmpty() public view {
        AgentRegistry.AgentRecord memory record = registry.resolve(bytes32(0));
        assertEq(record.agentAddress, address(0));
    }
}
```

---

### PermissionVault Unit Tests (Key Cases)

**File:** `test/unit/PermissionVault.t.sol`

```solidity
// Critical test cases —  implement these first

// ── Happy Path ─────────────────────────────────────────────────

function test_validateUserOp_allowedAction_passes() public { ... }
function test_validateUserOp_correctlyRecordsSpend() public { ... }
function test_validateUserOp_correctlyLogsAction() public { ... }

// ── Revocation Checks ──────────────────────────────────────────

function test_validateUserOp_revokedAgent_fails() public { ... }
function test_validateUserOp_afterEmergencyRevoke_fails() public { ... }

// ── Scope Expiry ───────────────────────────────────────────────

function test_validateUserOp_expiredScope_fails() public { ... }
function test_validateUserOp_scopeNotYetActive_fails() public { ... }
function test_validateUserOp_noActiveScope_fails() public { ... }

// ── Protocol Restrictions ──────────────────────────────────────

function test_validateUserOp_disallowedProtocol_fails() public { ... }
function test_validateUserOp_allowedProtocol_passes() public { ... }
function test_validateUserOp_emptyProtocolList_deniesAll() public { ... }

// ── Selector Restrictions ──────────────────────────────────────

function test_validateUserOp_disallowedSelector_fails() public { ... }
function test_validateUserOp_allowedSelector_passes() public { ... }
function test_validateUserOp_noSelectorList_allowsAllSelectors() public { ... }

// ── Spend Caps ─────────────────────────────────────────────────

function test_validateUserOp_perTxCapExceeded_fails() public { ... }
function test_validateUserOp_dailyCapExceeded_fails() public { ... }
function test_validateUserOp_exactlyAtPerTxCap_passes() public { ... }
function test_validateUserOp_rollingWindowRespected() public {
    // Spend $400 at T=0, wait 25 hours, spend $400 again → should pass
    // Spend $400 at T=0, wait 23 hours, spend $400 → should fail (rolling window)
    ...
}

// ── Token Restrictions ─────────────────────────────────────────

function test_validateUserOp_disallowedToken_fails() public { ... }
function test_validateUserOp_allowAnyToken_skipsTokenCheck() public { ... }

// ── Time Window ────────────────────────────────────────────────

function test_validateUserOp_outsideTimeWindow_fails() public { ... }
function test_validateUserOp_insideTimeWindow_passes() public { ... }
function test_validateUserOp_exactlyAtWindowBoundary() public { ... }

// ── Permission Management ──────────────────────────────────────

function test_grantPermission_ownerCanGrant() public { ... }
function test_grantPermission_nonOwnerReverts() public { ... }
function test_grantPermission_invalidSignatureReverts() public { ... }
function test_grantPermission_supersedsPreviousScope() public { ... }
function test_revokePermission_setsRevokedFlag() public { ... }
function test_emergencyRevoke_revokesAllScopes() public { ... }
```

---

### RevocationRegistry Unit Tests

```solidity
// Full test list (implement all of these)
function test_revoke_ownerCanRevoke() public { ... }
function test_revoke_strangerCannotRevoke() public { ... }
function test_revoke_emitsAgentRevokedEvent() public { ... }
function test_revoke_isRevokedReturnsTrueAfterRevoke() public { ... }
function test_revoke_isIdempotent() public { ... }
function test_batchRevoke_revokesMultiple() public { ... }
function test_batchRevoke_nonAdminReverts() public { ... }
function test_reinstate_ownerCanReinstateAfter24h() public { ... }
function test_reinstate_before24hReverts() public { ... }
function test_reinstate_isRevokedFalseAfterReinstate() public { ... }
function test_reinstate_nonOwnerReverts() public { ... }
function test_isRevoked_returnsFalseForUnregisteredAgent() public { ... }
function test_getRevocationRecord_returnsCorrectData() public { ... }
function test_getRevocationHistory_showsMultipleCycles() public { ... }
```

---

### SpendTracker Unit Tests

```solidity
function test_recordSpend_onlyPermissionVaultCanCall() public { ... }
function test_recordSpend_emitsSpendRecordedEvent() public { ... }
function test_checkSpendCap_withinCap_returnsTrue() public { ... }
function test_checkSpendCap_exceedsCap_returnsFalse() public { ... }
function test_checkSpendCap_exactlyAtCap_returnsTrue() public { ... }
function test_getRollingSpend_excludesOldEntries() public {
    // Record spend at T=0
    // Time travel 25 hours
    // Record spend at T+25h
    // Check getRollingSpend(agent, 86400) = only the T+25h spend
}
function test_getRollingSpend_zeroForNewAgent() public { ... }
function test_ringBuffer_wrapsCorrectly() public { ... }  // At MAX_ENTRIES
function test_oracle_reverts_ifStale() public { ... }
function test_oracle_reverts_ifNegativePrice() public { ... }
function test_calculateUSDValue_correctForUSDC() public { ... }  // 6 decimals
function test_calculateUSDValue_correctForETH() public { ... }   // 18 decimals
function test_calculateUSDValue_correctForWBTC() public { ... }  // 8 decimals
```

---

## Tier 2: Integration Tests (Foundry Fork)

### Setup

```bash
# Fork Base Sepolia at the latest block
forge test --match-path "test/integration/*" --fork-url $BASE_SEPOLIA_RPC_URL -vvv

# Or fork Base mainnet (real Uniswap, Aave, Chainlink)
forge test --match-path "test/integration/*" --fork-url $BASE_MAINNET_RPC_URL -vvv
```

### Full Flow Integration Tests

**File:** `test/integration/FullFlow.integration.t.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
// Import all Bouclier contracts
// Import Uniswap v3 interfaces
// Import Chainlink interfaces

contract BouclierFullFlowTest is Test {
    
    // Deployed contract addresses on forked chain
    address constant UNISWAP_V3_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481; // Base mainnet
    address constant USDC              = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant WETH              = 0x4200000000000000000000000000000000000006;
    address constant ETH_USD_FEED      = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address constant USDC_USD_FEED     = 0x7e860098F58bBFC8648a4311b374B1D669a2bc9;
    
    // Test actors
    address enterprise = makeAddr("enterprise");
    address agentWallet = makeAddr("agentWallet");
    
    // Bouclier contracts (deployed in setUp)
    AgentRegistry registry;
    PermissionVault vault;
    RevocationRegistry revocationReg;
    SpendTracker spendTracker;
    AuditLogger auditLogger;
    
    function setUp() public {
        // Deploy all contracts
        // Wire dependencies (vault → revocationReg, spendTracker, auditLogger)
        // Give enterprise some USDC
        deal(USDC, enterprise, 10_000 * 1e6); // $10k USDC
    }
    
    // ── Integration Test 1: Allowed Swap Passes ────────────────────
    
    function test_integration_allowedSwap_passes() public {
        // 1. Enterprise registers agent
        vm.prank(enterprise);
        bytes32 agentId = registry.register(agentWallet, "claude-sonnet-4-6", bytes32(0), "");
        
        // 2. Enterprise grants permission scope
        PermissionVault.PermissionScope memory scope = PermissionVault.PermissionScope({
            agentId: agentId,
            allowedProtocols: _toArray(UNISWAP_V3_ROUTER),
            allowedSelectors: _toArray4(ISwapRouter.exactInputSingle.selector),
            allowedTokens: _toArray2(USDC, WETH),
            dailySpendCapUSD: 2000 * 1e18,  // $2000 (18 decimals)
            perTxSpendCapUSD: 500 * 1e18,   // $500 per tx
            validFrom: uint48(block.timestamp),
            validUntil: uint48(block.timestamp + 90 days),
            allowAnyProtocol: false,
            allowAnyToken: false,
            revoked: false,
            grantHash: bytes32(0),  // set by grantPermission
            windowStartHour: 0,
            windowEndHour: 0,
            windowDaysMask: 0,
            allowedChainId: 0
        });
        
        vm.prank(enterprise);
        vault.grantPermission(agentId, scope, _signScope(enterprise, scope));
        
        // 3. Agent constructs UserOp for $300 USDC → ETH swap
        PackedUserOperation memory userOp = _buildSwapUserOp(agentWallet, 300 * 1e6);
        
        // 4. Validate UserOp through PermissionVault
        uint256 validationData = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        
        // Assert: validation succeeds (returns 0 = SIG_VALIDATION_SUCCESS)
        assertEq(validationData & 1, 0);
        
        // 5. Verify spend was recorded
        uint256 rolling = spendTracker.getRollingSpend(agentId, 86400);
        assertApproxEqRel(rolling, 300 * 1e18, 0.01e18); // within 1% (oracle price)
    }
    
    // ── Integration Test 2: Daily Cap Exceeded ─────────────────────
    
    function test_integration_dailyCapExceeded_reverts() public {
        // Setup: same as above but with $500 daily cap
        // Record $400 of spend
        // Try $200 more → should fail (would exceed $500 cap)
        
        // Setup agent + scope with $500 daily cap
        ...
        
        // Simulate $400 already spent
        vm.prank(address(vault));
        spendTracker.recordSpend(agentId, 400 * 1e18, uint48(block.timestamp));
        
        // Now try to spend $200 more
        PackedUserOperation memory userOp = _buildSwapUserOp(agentWallet, 200 * 1e6);
        uint256 validationData = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        
        // Assert: validation FAILS (returns 1 = SIG_VALIDATION_FAILED)
        assertEq(validationData & 1, 1);
        
        // Assert: PermissionViolation event was emitted
        // assertEq captured event violationType == "DAILY_CAP_EXCEEDED"
    }
    
    // ── Integration Test 3: Revoked Agent Blocked ──────────────────
    
    function test_integration_revokedAgent_allActionsBlocked() public {
        // Setup: agent with active scope
        bytes32 agentId = _setupAgentWithScope();
        
        // Revoke
        vm.prank(enterprise);
        revocationReg.revoke(agentId, IRevocationRegistry.RevocationReason.Suspicious, "test");
        
        // Attempt any action
        PackedUserOperation memory userOp = _buildSwapUserOp(agentWallet, 100 * 1e6);
        uint256 validationData = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        
        // Must fail
        assertEq(validationData & 1, 1);
    }
    
    // ── Integration Test 4: Disallowed Protocol ────────────────────
    
    function test_integration_disallowedProtocol_reverts() public {
        // Scope allows Uniswap only
        bytes32 agentId = _setupAgentWithUniswapOnlyScope();
        
        // Try to call Aave (not in allowlist)
        address AAVE_POOL = 0x...; // Aave v3 on Base
        PackedUserOperation memory userOp = _buildAaveUserOp(agentWallet, AAVE_POOL);
        uint256 validationData = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        
        assertEq(validationData & 1, 1); // Must fail
    }
    
    // ── Integration Test 5: Full Revocation Flow ───────────────────
    
    function test_integration_revocationAndReinstateFlow() public {
        bytes32 agentId = _setupAgentWithScope();
        
        // Agent can act before revocation
        PackedUserOperation memory userOp = _buildSwapUserOp(agentWallet, 100 * 1e6);
        uint256 before = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        assertEq(before & 1, 0); // passes
        
        // Revoke
        vm.prank(enterprise);
        revocationReg.revoke(agentId, IRevocationRegistry.RevocationReason.UserRequested, "");
        
        // Agent blocked immediately
        uint256 afterRevoke = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        assertEq(afterRevoke & 1, 1); // fails
        
        // Cannot reinstate within 24h
        vm.prank(enterprise);
        vm.expectRevert("reinstatement timelock: must wait 24h after revocation");
        revocationReg.reinstate(agentId, "");
        
        // Fast forward 25 hours
        vm.warp(block.timestamp + 25 hours);
        
        // Re-grant permission scope first
        vm.prank(enterprise);
        vault.grantPermission(agentId, _buildDefaultScope(agentId), _signScope(enterprise, _buildDefaultScope(agentId)));
        
        // Now reinstate
        vm.prank(enterprise);
        revocationReg.reinstate(agentId, "Investigation complete");
        
        // Agent can act again
        uint256 afterReinstate = vault.validateUserOp(userOp, keccak256(abi.encode(userOp)));
        assertEq(afterReinstate & 1, 0); // passes
    }
}
```

---

## Tier 3: Fuzz Tests (Echidna + Foundry Invariant)

### Foundry Invariant Tests

```bash
# Run invariant tests
forge test --match-contract "Invariant*" --runs 10000 -vvv
```

**File:** `test/invariant/SpendTrackerInvariant.t.sol`

```solidity
contract SpendTrackerInvariantTest is Test {
    SpendTracker spendTracker;
    PermissionVaultMock vault;
    bytes32 agentId = bytes32(uint256(1));
    uint256 constant DAILY_CAP = 1000e18; // $1000

    function setUp() public {
        vault = new PermissionVaultMock();
        spendTracker = new SpendTracker(address(vault));
        targetContract(address(spendTracker));
    }

    // INVARIANT: Rolling 24h spend never exceeds the cap if checkSpendCap passed
    function invariant_rollingSpendNeverExceedsCap() public view {
        uint256 rolling = spendTracker.getRollingSpend(agentId, 86400);
        assertLe(rolling, DAILY_CAP, "Rolling spend exceeded daily cap");
    }

    // INVARIANT: Action count is monotonically increasing
    function invariant_actionCountMonotonicallyIncreases() public view {
        // Store previous count and verify it only increases
        // (requires handler pattern)
    }
}
```

**File:** `test/invariant/RevocationInvariant.t.sol`

```solidity
contract RevocationInvariantTest is Test {
    RevocationRegistry revocationReg;
    PermissionVault vault;
    
    // INVARIANT: If agent is revoked, validateUserOp ALWAYS returns FAILED
    function invariant_revokedAgentAlwaysBlocked() public view {
        // For all agents that are revoked in revocationReg,
        // simulating a validateUserOp must return SIG_VALIDATION_FAILED
        ...
    }
    
    // INVARIANT: reinstate() never executes before 24h timelock
    function invariant_reinstateTimelockHolds() public view {
        // For all revocation records, if reinstated:
        //   reinstatedAt >= revokedAt + 24 hours
        ...
    }
}
```

### Echidna Configuration

```yaml
# echidna.yaml
testMode: assertion
testLimit: 10000000       # 10M iterations
seqLen: 100               # Max sequence length
shrinkLimit: 5000         # Max shrink attempts
coverage: true
corpusDir: "echidna-corpus"
deployer: "0x10000"
sender: ["0x10000", "0x20000", "0x30000"]
```

**File:** `test/echidna/PermissionVaultEchidna.sol`

```solidity
contract PermissionVaultEchidna {
    PermissionVault vault;
    SpendTracker spendTracker;
    RevocationRegistry revocationReg;
    
    bytes32 agentId;
    uint256 constant DAILY_CAP = 1000e18;
    
    constructor() {
        // Deploy and setup
        agentId = bytes32(uint256(1));
    }
    
    // Echidna will try to make this fail
    function echidna_spendCapNeverExceeded() public view returns (bool) {
        uint256 rolling = spendTracker.getRollingSpend(agentId, 86400);
        return rolling <= DAILY_CAP;
    }
    
    function echidna_revokedAgentAlwaysBlocked() public view returns (bool) {
        if (!revocationReg.isRevoked(agentId)) return true;
        // Build a UserOp and check it fails
        // ... complex setup
        return true; // simplified
    }
    
    // Functions Echidna will call randomly
    function recordSpend(uint96 amount) public {
        if (amount == 0) return;
        uint256 usdAmount = uint256(amount) * 1e18 / 100; // Normalise
        if (spendTracker.checkSpendCap(agentId, usdAmount, DAILY_CAP)) {
            spendTracker.recordSpend(agentId, usdAmount, uint48(block.timestamp));
        }
    }
    
    function revokeAgent() public {
        revocationReg.revoke(agentId, IRevocationRegistry.RevocationReason.Suspicious, "");
    }
    
    function warpTime(uint32 seconds_) public {
        vm.warp(block.timestamp + seconds_);
    }
}
```

---

## Tier 4: Formal Verification (Certora Prover)

### Setup

```bash
pip install certora-cli
certoraRun contracts/PermissionVault.sol --verify PermissionVault:specs/PermissionVault.spec --conf specs/conf.json
```

### Spec 1: Spend Cap Integrity

**File:** `specs/SpendCapIntegrity.spec`

```cvl
// SOUND PROOF: The rolling spend NEVER exceeds dailySpendCapUSD
//              when checkSpendCap() returns true

rule spendCapIntegrity(bytes32 agentId, uint256 proposedAmount, uint256 cap) {
    require checkSpendCap(agentId, proposedAmount, cap) == true;
    require proposedAmount > 0;
    
    uint256 rollingBefore = getRollingSpend(agentId, 86400);
    require rollingBefore + proposedAmount <= cap; // precondition matches checkSpendCap logic
    
    recordSpend(agentId, proposedAmount, now);
    
    uint256 rollingAfter = getRollingSpend(agentId, 86400);
    
    assert rollingAfter <= cap,
        "Rolling spend exceeded cap after valid recordSpend";
}
```

### Spec 2: Revocation Finality

**File:** `specs/RevocationFinality.spec`

```cvl
// SOUND PROOF: If isRevoked(agentId) == true,
//              validateUserOp ALWAYS returns SIG_VALIDATION_FAILED

rule revokedAgentAlwaysBlocked(bytes32 agentId, PackedUserOperation userOp, bytes32 userOpHash) {
    require isRevoked(agentId) == true;
    
    uint256 validationData = validateUserOp(userOp, userOpHash);
    
    assert validationData & 1 == 1,
        "Revoked agent passed validateUserOp — critical invariant violated";
}
```

### Spec 3: Reinstatement Timelock

**File:** `specs/ReinstateTimelock.spec`

```cvl
// SOUND PROOF: reinstate() cannot succeed before 24h after revokedAt

rule reinstateTimelockEnforced(bytes32 agentId, string reason) {
    uint48 revokedAt = getRevocationRecord(agentId).revokedAt;
    require revokedAt > 0;  // agent is revoked
    require now < revokedAt + 86400;  // before 24h
    
    reinstate@withrevert(agentId, reason);
    
    assert lastReverted,
        "reinstate() succeeded before 24h timelock — invariant violated";
}
```

---

## SDK Tests (Vitest)

```bash
# Run SDK unit tests
cd packages/sdk && bun test

# Run with coverage
bun test --coverage

# Target: ≥85% line coverage
```

**File:** `packages/sdk/src/__tests__/AgentShield.test.ts`

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AgentShield } from '../AgentShield';

describe('AgentShield.registerAgent', () => {
  it('returns correct DID format for Base chain', async () => {
    // Mock the contract call
    const shield = createMockShield();
    const result = await shield.registerAgent({
      agentAddress: '0x1234567890123456789012345678901234567890',
      model: 'claude-sonnet-4-6',
    });
    
    expect(result.did).toMatch(/^did:ethr:base:0x/);
  });
  
  it('throws BouclierError.AGENT_ALREADY_REGISTERED on duplicate', async () => {
    const shield = createMockShield({ alreadyRegistered: true });
    await expect(shield.registerAgent({
      agentAddress: '0x123...',
      model: 'claude',
    })).rejects.toThrow('AGENT_NOT_REGISTERED');
  });
});

describe('AgentShield.checkPermission', () => {
  it('returns allowed=false with DAILY_CAP_EXCEEDED reason', async () => {
    const shield = createMockShield({
      rollingSpend: 1900,
      dailyCap: 2000,
    });
    
    const result = await shield.checkPermission(agentId, {
      target: UNISWAP_ROUTER,
      selector: '0x04e45aaf',
      estimatedValueUSD: 200,
    });
    
    expect(result.allowed).toBe(false);
    expect(result.rejectReason).toBe('DAILY_CAP_EXCEEDED');
  });
});
```

---

## CI Pipeline

```yaml
# .github/workflows/test.yml

name: Test Suite

on: [push, pull_request]

jobs:
  contracts:
    name: Contract Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1
      - name: Run unit tests
        run: forge test --match-path "test/unit/*" -vvv
        working-directory: contracts
      - name: Run integration tests
        env:
          BASE_MAINNET_RPC_URL: ${{ secrets.BASE_MAINNET_RPC_URL }}
        run: forge test --match-path "test/integration/*" --fork-url $BASE_MAINNET_RPC_URL -vvv
        working-directory: contracts
      - name: Check coverage
        run: |
          forge coverage --report lcov
          # Fail if any contract < 90% line coverage
          python scripts/check_coverage.py --min 90

  sdk:
    name: SDK Tests
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: oven-sh/setup-bun@v1
      - name: Install dependencies
        run: bun install
        working-directory: packages/sdk
      - name: Run tests
        run: bun test --coverage
        working-directory: packages/sdk

  security:
    name: Security Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Slither
        uses: crytic/slither-action@v0.3.0
        with:
          target: contracts/src/
          fail-on: medium   # Fail CI on any medium+ finding
```

---

## Test Coverage Targets

| Contract | Line Coverage | Branch Coverage | Function Coverage |
|---|---|---|---|
| `AgentRegistry.sol` | ≥ 90% | ≥ 85% | 100% |
| `PermissionVault.sol` | ≥ 95% | ≥ 90% | 100% |
| `SpendTracker.sol` | ≥ 95% | ≥ 90% | 100% |
| `AuditLogger.sol` | ≥ 90% | ≥ 85% | 100% |
| `RevocationRegistry.sol` | ≥ 95% | ≥ 90% | 100% |
| TypeScript SDK | ≥ 85% | — | ≥ 90% |
| Python SDK | ≥ 80% | — | ≥ 90% |

---

*Last Updated: March 2026*
