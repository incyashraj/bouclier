# PermissionVault.sol — Contract Architecture

> **Contract:** `PermissionVault.sol`  
> **Layer:** Permission + Enforcement Layer  
> **Dependencies:** `RevocationRegistry`, `SpendTracker`, `AuditLogger`  
> **Implements:** ERC-7579 `IValidator`, ERC-4337 UserOp validation  
> **This is the core contract of the Bouclier protocol.**

---

## Purpose

`PermissionVault` is the enforcement engine. It is built as an **ERC-7579 Validator Module** — it plugs into any ERC-7579-compatible smart account and intercepts every transaction that account would otherwise execute.

For every UserOperation an AI agent attempts to broadcast:
1. It checks the agent is registered and not revoked
2. It validates the intended action against all active permission scopes
3. It checks the action does not exceed spend caps
4. If all checks pass, it records the spend and logs the action
5. Only then does it return `SIG_VALIDATION_SUCCESS`

If any check fails, the UserOp is reverted before reaching the blockchain.

---

## Full Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IValidator } from "erc7579/interfaces/IERC7579Module.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";

interface IPermissionVault is IValidator {

    // ─────────────────────────────────────────────────────────────────
    // STRUCTS
    // ─────────────────────────────────────────────────────────────────

    struct PermissionScope {
        bytes32  agentId;
        address[] allowedProtocols;    // Contract addresses allowed as targets
        bytes4[]  allowedSelectors;    // Function selectors allowed to be called
        address[] allowedTokens;       // ERC-20 token addresses the agent may touch
        uint256  dailySpendCapUSD;     // Max USD (18 decimals) in any rolling 24h window
        uint256  perTxSpendCapUSD;     // Max USD per single transaction
        uint48   validFrom;            // Unix timestamp: scope starts
        uint48   validUntil;           // Unix timestamp: scope expires (0 = no expiry)
        bool     allowAnyProtocol;     // Override: skip protocol check (use with caution)
        bool     allowAnyToken;        // Override: skip token check
        bool     revoked;              // Set to true by revoke operations
        bytes32  grantHash;            // EIP-712 hash of the grant for off-chain verification
        // Time window (optional)
        uint8    windowStartHour;      // UTC hour 0-23 (0 = disabled)
        uint8    windowEndHour;        // UTC hour 0-23
        uint8    windowDaysMask;       // Bitmask: bit 0 = Monday, bit 6 = Sunday
        // Chain restriction
        uint64   allowedChainId;       // 0 = current chain only, type(uint64).max = any chain
    }

    struct ValidationResult {
        bool     allowed;
        string   rejectReason;   // Only set if !allowed (for SDK-level pre-flight)
        uint256  remainingDaily; // Remaining daily cap after this tx
    }

    // ─────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────

    event PermissionGranted(
        bytes32 indexed agentId,
        bytes32 indexed scopeId,
        address indexed grantedBy,
        uint48  validUntil,
        uint48  timestamp
    );

    event PermissionRevoked(
        bytes32 indexed agentId,
        bytes32 indexed scopeId,
        address indexed revokedBy,
        uint48  timestamp
    );

    event PermissionViolation(
        bytes32 indexed agentId,
        address indexed violatingTarget,
        bytes4  violatingSelector,
        string  violationType,   // "PROTOCOL_NOT_ALLOWED" | "SPEND_CAP_EXCEEDED" | "TOKEN_NOT_ALLOWED" | etc.
        uint48  timestamp
    );

    event ActionValidated(
        bytes32 indexed agentId,
        bytes32 indexed userOpHash,
        uint256 usdValue,
        uint48  timestamp
    );

    // ─────────────────────────────────────────────────────────────────
    // ERC-7579 REQUIRED FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Called by the ERC-7579 smart account during UserOp validation
     * @dev This is the hot path — called on EVERY agent transaction
     *      Must be gas-optimised. All checks inline, no external calls on failure path.
     * @param userOp     The packed UserOperation from the agent
     * @param userOpHash keccak256 of the UserOp (for logging)
     * @return validationData  SIG_VALIDATION_SUCCESS (0) or SIG_VALIDATION_FAILED (1)
     *                         Packed with validUntil/validAfter for time-bound scopes
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256 validationData);

    /**
     * @notice ERC-1271 signature validation (for ERC-7579 isValidSignatureWithSender)
     */
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4 magicValue);

    /**
     * @notice Called when this module is installed on a smart account
     * @param data  Encoded initialisation data (agentId)
     */
    function onInstall(bytes calldata data) external override;

    /**
     * @notice Called when this module is uninstalled from a smart account
     * @param data  Encoded cleanup data
     */
    function onUninstall(bytes calldata data) external override;

    /**
     * @notice Returns module type (ERC-7579 module type 1 = validator)
     */
    function isModuleType(uint256 typeID) external pure override returns (bool);

    // ─────────────────────────────────────────────────────────────────
    // PERMISSION MANAGEMENT
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Grants a permission scope to an agent
     * @dev Only callable by the agent's owner (verified via AgentRegistry)
     *      Uses EIP-712 signature to allow off-chain signing and on-chain grant
     * @param agentId   The agent receiving permissions
     * @param scope     The full PermissionScope struct
     * @param signature EIP-712 signature from the agent owner
     * @return scopeId  Unique identifier for this scope grant
     */
    function grantPermission(
        bytes32 agentId,
        PermissionScope calldata scope,
        bytes calldata signature
    ) external returns (bytes32 scopeId);

    /**
     * @notice Revokes a specific scope (surgical revocation)
     * @dev Only callable by the agent's owner
     * @param scopeId  The scope to revoke
     */
    function revokePermission(bytes32 scopeId) external;

    /**
     * @notice Emergency revoke: disables ALL scopes for an agent immediately
     * @dev Callable by: agent owner, protocol admin, or RevocationRegistry
     *      This is the kill switch. Emits PermissionRevoked for every active scope.
     * @param agentId  The agent to emergency-revoke
     */
    function emergencyRevoke(bytes32 agentId) external;

    // ─────────────────────────────────────────────────────────────────
    // READ FUNCTIONS
    // ─────────────────────────────────────────────────────────────────

    /**
     * @notice Pre-flight check: returns whether an action would be allowed
     * @dev Called by the SDK BEFORE constructing a UserOp — early rejection
     *      Does NOT record spend or log action (read-only)
     * @param agentId  The agent
     * @param target   Target contract address
     * @param selector Function selector (first 4 bytes of calldata)
     * @param valueUSD Estimated USD value of the transaction
     * @return result  Full ValidationResult with allowed bool and reject reason
     */
    function checkPermission(
        bytes32 agentId,
        address target,
        bytes4  selector,
        uint256 valueUSD
    ) external view returns (ValidationResult memory result);

    /**
     * @notice Gets the active scope for an agent
     * @param agentId  The agent
     * @return scope   Current active PermissionScope (reverted = none active)
     */
    function getActiveScope(bytes32 agentId) external view returns (PermissionScope memory scope);

    /**
     * @notice Gets all historical scopes for an agent (including revoked)
     * @param agentId  The agent
     * @return scopeIds  Array of all scope IDs ever granted to this agent
     */
    function getScopeHistory(bytes32 agentId) external view returns (bytes32[] memory scopeIds);

    /**
     * @notice Gets a scope by its ID
     * @param scopeId  The scope identifier
     * @return scope   The full PermissionScope struct
     */
    function getScope(bytes32 scopeId) external view returns (PermissionScope memory scope);
}
```

---

## Core Logic: `validateUserOp` Implementation

This is the most critical function in the protocol. Every line must be correct.

```solidity
function validateUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash
) external override returns (uint256 validationData) {
    
    // ── Step 1: Extract agent identity ────────────────────────────────
    bytes32 agentId = _agentIdFromCaller(userOp.sender);
    // If sender not registered → revert (not just validation failure)
    require(agentId != bytes32(0), "PermissionVault: unregistered agent");

    // ── Step 2: Revocation check (FASTEST — check this first) ─────────
    // Reads Redis cache via off-chain node, falls back to on-chain
    if (revocationRegistry.isRevoked(agentId)) {
        emit PermissionViolation(agentId, userOp.sender, bytes4(0), "AGENT_REVOKED", uint48(block.timestamp));
        return SIG_VALIDATION_FAILED;
    }

    // ── Step 3: Get active scope ───────────────────────────────────────
    PermissionScope storage scope = _activeScopes[agentId];
    
    // Check scope exists and hasn't expired
    if (scope.agentId == bytes32(0)) {
        emit PermissionViolation(agentId, userOp.sender, bytes4(0), "NO_ACTIVE_SCOPE", uint48(block.timestamp));
        return SIG_VALIDATION_FAILED;
    }
    if (scope.validUntil != 0 && block.timestamp > scope.validUntil) {
        emit PermissionViolation(agentId, userOp.sender, bytes4(0), "SCOPE_EXPIRED", uint48(block.timestamp));
        return SIG_VALIDATION_FAILED;
    }
    if (block.timestamp < scope.validFrom) {
        emit PermissionViolation(agentId, userOp.sender, bytes4(0), "SCOPE_NOT_YET_VALID", uint48(block.timestamp));
        return SIG_VALIDATION_FAILED;
    }

    // ── Step 4: Decode calldata ────────────────────────────────────────
    (address target, uint256 value, bytes memory callData) = _decodeExecution(userOp.callData);
    bytes4 selector = callData.length >= 4 ? bytes4(callData[:4]) : bytes4(0);

    // ── Step 5: Protocol allowlist check ──────────────────────────────
    if (!scope.allowAnyProtocol) {
        bool protocolAllowed = false;
        for (uint i = 0; i < scope.allowedProtocols.length; i++) {
            if (scope.allowedProtocols[i] == target) {
                protocolAllowed = true;
                break;
            }
        }
        if (!protocolAllowed) {
            emit PermissionViolation(agentId, target, selector, "PROTOCOL_NOT_ALLOWED", uint48(block.timestamp));
            return SIG_VALIDATION_FAILED;
        }
    }

    // ── Step 6: Function selector check ───────────────────────────────
    if (scope.allowedSelectors.length > 0) {
        bool selectorAllowed = false;
        for (uint i = 0; i < scope.allowedSelectors.length; i++) {
            if (scope.allowedSelectors[i] == selector) {
                selectorAllowed = true;
                break;
            }
        }
        if (!selectorAllowed) {
            emit PermissionViolation(agentId, target, selector, "SELECTOR_NOT_ALLOWED", uint48(block.timestamp));
            return SIG_VALIDATION_FAILED;
        }
    }

    // ── Step 7: Time window check ──────────────────────────────────────
    if (scope.windowStartHour != 0 || scope.windowEndHour != 0) {
        if (!_isWithinTimeWindow(scope)) {
            emit PermissionViolation(agentId, target, selector, "OUTSIDE_TIME_WINDOW", uint48(block.timestamp));
            return SIG_VALIDATION_FAILED;
        }
    }

    // ── Step 8: USD value calculation via Chainlink ────────────────────
    uint256 usdValue = _calculateUsdValue(target, value, callData);

    // ── Step 9: Per-transaction spend cap ─────────────────────────────
    if (usdValue > scope.perTxSpendCapUSD) {
        emit PermissionViolation(agentId, target, selector, "PER_TX_CAP_EXCEEDED", uint48(block.timestamp));
        return SIG_VALIDATION_FAILED;
    }

    // ── Step 10: Rolling daily spend cap ──────────────────────────────
    if (!spendTracker.checkSpendCap(agentId, usdValue, scope.dailySpendCapUSD)) {
        emit PermissionViolation(agentId, target, selector, "DAILY_CAP_EXCEEDED", uint48(block.timestamp));
        return SIG_VALIDATION_FAILED;
    }

    // ── Step 11: Token whitelist check (if applicable) ─────────────────
    if (!scope.allowAnyToken) {
        // Extract all token addresses touched by this calldata
        address[] memory tokensUsed = _extractTokensFromCalldata(target, callData);
        for (uint i = 0; i < tokensUsed.length; i++) {
            bool tokenAllowed = false;
            for (uint j = 0; j < scope.allowedTokens.length; j++) {
                if (scope.allowedTokens[j] == tokensUsed[i]) {
                    tokenAllowed = true;
                    break;
                }
            }
            if (!tokenAllowed) {
                emit PermissionViolation(agentId, target, selector, "TOKEN_NOT_ALLOWED", uint48(block.timestamp));
                return SIG_VALIDATION_FAILED;
            }
        }
    }

    // ── All checks passed ─────────────────────────────────────────────

    // Step 12: Record spend (state write — must be after all checks)
    spendTracker.recordSpend(agentId, usdValue, uint48(block.timestamp));

    // Step 13: Log action to AuditLogger
    auditLogger.logAction(agentId, userOpHash, ""); // IPFS CID added async off-chain

    // Step 14: Emit validation event
    emit ActionValidated(agentId, userOpHash, usdValue, uint48(block.timestamp));

    // Step 15: Pack validation data with time bounds for ERC-4337
    // validAfter = scope.validFrom, validUntil = scope.validUntil
    validationData = _packValidationData(
        false,             // not failed
        scope.validUntil,  // packed into upper bits
        scope.validFrom    // packed into middle bits
    );
}
```

---

## EIP-712 Grant Schema

Permission grants are signed off-chain using EIP-712 and verified on-chain in `grantPermission()`:

```solidity
bytes32 constant PERMISSION_SCOPE_TYPEHASH = keccak256(
    "PermissionScope("
    "bytes32 agentId,"
    "address[] allowedProtocols,"
    "bytes4[] allowedSelectors,"
    "address[] allowedTokens,"
    "uint256 dailySpendCapUSD,"
    "uint256 perTxSpendCapUSD,"
    "uint48 validFrom,"
    "uint48 validUntil"
    ")"
);
```

This allows an enterprise to construct a permission grant, sign it with their hardware wallet off-chain, and hand the signature to a relay to submit. The enterprise never needs to be online during the grant transaction.

---

## Storage Layout

```solidity
// PermissionVault.sol storage

// Agent ID → active scope ID (one active scope per agent at a time)
mapping(bytes32 => bytes32) private _agentActiveScope;

// Scope ID → full scope struct
mapping(bytes32 => PermissionScope) private _scopes;

// Agent ID → all scope IDs ever granted (for history)
mapping(bytes32 => bytes32[]) private _agentScopeHistory;

// Scope ID derivation: keccak256(agentId, grantHash, block.timestamp)
```

**Design choice: one active scope per agent**  
An agent has exactly one active permission scope at a time. To change permissions, the owner grants a new scope (which supersedes the old one). This is simpler, safer, and easier to audit than multiple overlapping scopes.

---

## Security Analysis

| Attack Vector | Description | Mitigation |
|---|---|---|
| Calldata encoding bypass | Craft calldata that passes selector check but does something else | Full calldata parsing for known protocols (Uniswap, Aave ABI-decoded) |
| Oracle manipulation | Inflate token price in Chainlink feed to pass spend cap check | Multi-oracle aggregation + TWAP + circuit breaker on deviation > 5% |
| Replay attack | Re-broadcast an old UserOp after revocation | ERC-4337 nonce tracking in EntryPoint (per-agent nonce, non-decreasing) |
| Reentrancy | Malicious target calls back into PermissionVault during validation | Validating not executing — `validateUserOp` never calls external untrusted contracts |
| Permission scope front-running | Watch mempool for `grantPermission`, front-run with a spend | EIP-712 off-chain grant is atomic with the permission becoming active; no window |
| Storage collision | ERC-7579 module storage collides with account storage | Use ERC-7201 namespaced storage (`@custom:storage-location erc7201:bouclier.vault`) |
| emergencyRevoke race condition | Attacker sees revocation tx, front-runs with a large spend | Revocation submitted via Flashbots Protect; soft revocation (Redis) precedes on-chain |

---

## Gas Optimisation

```solidity
// 1. Revocation check FIRST — cheapest check, eliminates most attacker paths
// 2. Array iterations use cached length: uint256 len = arr.length — saves MLOAD per iter
// 3. PermissionScope packs small fields (uint8, uint48) into single storage slots
// 4. block.timestamp used at 5-minute granularity for spend windows (saves SLOAD count)
// 5. Protocol/selector arrays bounded to max 20 entries (configurable max constant)
// 6. Chainlink price oracle result cached in transient storage (EIP-1153) for batch UserOps
```

**Estimated gas for `validateUserOp` (happy path):**
- ~85,000 gas with 3 protocols in allowlist, 1 token checked
- ~110,000 gas with 10 protocols + 5 tokens (bounded maximum)

At Base mainnet prices this is ~$0.001 per validation — acceptable for any serious deployment.

---

## Test Cases Required

```
✓ validateUserOp — allowed action passes (all checks green)
✓ validateUserOp — revoked agent is rejected
✓ validateUserOp — expired scope is rejected  
✓ validateUserOp — target not in protocol allowlist → rejected
✓ validateUserOp — function selector not allowed → rejected
✓ validateUserOp — USD value > perTxSpendCap → rejected
✓ validateUserOp — USD value pushes rolling daily total over cap → rejected
✓ validateUserOp — token not in whitelist → rejected
✓ validateUserOp — outside time window → rejected
✓ validateUserOp — scope not yet valid (validFrom in future) → rejected
✓ grantPermission — owner can grant scope
✓ grantPermission — non-owner cannot grant scope
✓ grantPermission — invalid EIP-712 signature reverts
✓ emergencyRevoke — sets all scopes to revoked
✓ emergencyRevoke — subsequent validateUserOp fails
✓ checkPermission — pre-flight returns correct ValidationResult
✗ FUZZ: random UserOps on random scopes — invariant: spend never exceeds cap
✗ FUZZ: time window boundaries — no off-by-one at hour boundaries
✗ INVARIANT: if agent is revoked, validateUserOp ALWAYS returns FAILED
✗ INVARIANT: cumulative spend in any 24h window NEVER exceeds dailySpendCapUSD
```

---

## Integration Test: Full Uniswap v3 Swap on Base Sepolia Fork

```solidity
// test/integration/PermissionVault.integration.t.sol

function test_allowedSwap_passes() public {
    // Setup: register agent, grant scope with Uniswap v3 allowed, $500 daily cap
    // Action: agent attempts swap of $300 USDC → ETH
    // Expected: UserOp validates, swap executes, spend recorded
}

function test_swapExceedsDailyCap_reverts() public {
    // Setup: agent at $400 of $500 daily cap
    // Action: agent attempts swap of $200 (would put total at $600)
    // Expected: PermissionViolation("DAILY_CAP_EXCEEDED") emitted, tx reverted
}

function test_disallowedProtocol_reverts() public {
    // Setup: scope allows Uniswap only
    // Action: agent attempts to interact with Curve
    // Expected: PermissionViolation("PROTOCOL_NOT_ALLOWED") emitted
}

function test_revokedAgent_allActionsBlocked() public {
    // Setup: agent registered with active scope
    // Action: emergencyRevoke called, then agent attempts any action
    // Expected: all subsequent validateUserOp return SIG_VALIDATION_FAILED
}
```

---

*Last Updated: March 2026*
