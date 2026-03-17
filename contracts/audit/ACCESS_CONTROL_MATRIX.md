# Bouclier — Access Control Matrix

> **Last Updated:** Session 10  
> **Scope:** All 5 core contracts  

---

## PermissionVault

| Function | Visibility | Modifiers | Who Can Call | Notes |
|---|---|---|---|---|
| `validateUserOp` | external | `nonReentrant`, `whenNotPaused` | ERC-4337 EntryPoint | Hot path — validates every UserOp |
| `grantPermission` | external | `whenNotPaused` | Agent's owner (EIP-712 signature verified) | Signature must match `rec.owner` |
| `revokePermission` | external | — | Agent's owner or contract owner | Checks `msg.sender == rec.owner \|\| msg.sender == owner()` |
| `emergencyRevoke` | external | — | Agent's owner or contract owner | Also calls `revocationRegistry.revoke()` |
| `rescueETH` | external | `onlyOwner` | Contract owner only | Safety valve for accidentally-sent ETH |
| `pause` | external | `onlyOwner` | Contract owner only | Emergency stop |
| `unpause` | external | `onlyOwner` | Contract owner only | Resume operations |
| `receive` | external | — | Anyone | Always reverts — ETH rejection |
| `getActiveScope` | external | — | Anyone | View function |
| `grantNonces` | external | — | Anyone | View function |
| `DOMAIN_SEPARATOR` | external | — | Anyone | View function |
| `SCOPE_TYPEHASH` | external | — | Anyone | View function |
| `isModuleType` | external | — | Anyone | View function (ERC-7579) |
| `owner` | external | — | Anyone | View function (Ownable) |

---

## AgentRegistry

| Function | Visibility | Modifiers | Who Can Call | Notes |
|---|---|---|---|---|
| `register` | external | `whenNotPaused` | Anyone | By design — `msg.sender` becomes agent owner |
| `updateStatus` | external | — | Agent owner or admin | Checks `rec.owner == msg.sender \|\| msg.sender == admin` |
| `setPermissionVault` | external | — | Agent owner or admin | Same access check as `updateStatus` |
| `resolve` | external | — | Anyone | View function |
| `getAgentId` | external | — | Anyone | View function |
| `getAgentsByOwner` | external | — | Anyone | View function |
| `isActive` | external | — | Anyone | View function |
| `totalAgents` | external | — | Anyone | View function |

**Note:** `register()` being open is intentional. Anyone can register their own agent — `msg.sender` is bound as `rec.owner`, preventing impersonation.

---

## SpendTracker

| Function | Visibility | Modifiers | Who Can Call | Notes |
|---|---|---|---|---|
| `recordSpend` | external | `onlyRole(VAULT_ROLE)`, `whenNotPaused` | PermissionVault only | State-changing — updates ring buffer |
| `setPriceFeed` | external | `onlyRole(DEFAULT_ADMIN_ROLE)` | Admin only | Configures Chainlink oracle addresses + sets anchor price |
| `refreshAnchorPrice` | external | `onlyRole(DEFAULT_ADMIN_ROLE)` | Admin only | Updates circuit breaker anchor after legitimate price moves |
| `getAnchorPrice` | external | — | Anyone | View function — returns stored anchor price |
| `checkSpendCap` | external | — | Anyone | View function |
| `getRollingSpend` | external | — | Anyone | View function |
| `getUSDValue` | external | — | Anyone | View function — includes circuit breaker check against anchor |
| `pause` | external | `onlyRole(DEFAULT_ADMIN_ROLE)` | Admin only | Emergency stop |
| `unpause` | external | `onlyRole(DEFAULT_ADMIN_ROLE)` | Admin only | Resume operations |

**Roles:**
- `DEFAULT_ADMIN_ROLE` — deployer/admin
- `VAULT_ROLE` — PermissionVault contract address

---

## RevocationRegistry

| Function | Visibility | Modifiers | Who Can Call | Notes |
|---|---|---|---|---|
| `revoke` | external | `onlyRole(REVOKER_ROLE)`, `whenNotPaused` | Revoker role holders | Sets revocation flag |
| `batchRevoke` | external | `onlyRole(GUARDIAN_ROLE)`, `whenNotPaused` | Guardian role holders | Mass revocation |
| `reinstate` | external | `onlyRole(REVOKER_ROLE)`, `whenNotPaused` | Revoker role holders | Enforces 24h timelock |
| `emergencyReinstate` | external | `onlyRole(GUARDIAN_ROLE)`, `whenNotPaused` | Guardian role holders | Bypasses timelock |
| `isRevoked` | external | — | Anyone | View function |
| `getRevocationRecord` | external | — | Anyone | View function |
| `pause` | external | `onlyRole(GUARDIAN_ROLE)` | Guardian role holders | Emergency stop |
| `unpause` | external | `onlyRole(GUARDIAN_ROLE)` | Guardian role holders | Resume operations |

**Roles:**
- `DEFAULT_ADMIN_ROLE` — deployer/admin
- `REVOKER_ROLE` — PermissionVault + authorized revokers
- `GUARDIAN_ROLE` — emergency multisig

---

## AuditLogger

| Function | Visibility | Modifiers | Who Can Call | Notes |
|---|---|---|---|---|
| `logAction` | external | `onlyRole(LOGGER_ROLE)`, `whenNotPaused` | PermissionVault only | Append-only audit record |
| `addIPFSCID` | external | `onlyRole(IPFS_ROLE)` | Backend API only | Anchors IPFS hash post-hoc |
| `getAuditRecord` | external | — | Anyone | View function |
| `getAgentHistory` | external | — | Anyone | View function |
| `getTotalEvents` | external | — | Anyone | View function |
| `pause` | external | `onlyRole(DEFAULT_ADMIN_ROLE)` | Admin only | Emergency stop |
| `unpause` | external | `onlyRole(DEFAULT_ADMIN_ROLE)` | Admin only | Resume operations |

**Roles:**
- `DEFAULT_ADMIN_ROLE` — deployer/admin
- `LOGGER_ROLE` — PermissionVault contract address
- `IPFS_ROLE` — backend API service

---

## Cross-Contract Call Graph

```
PermissionVault.validateUserOp()
  ├─► AgentRegistry.getAgentId()           [view]
  ├─► AgentRegistry.resolve()              [view]
  ├─► AgentRegistry.isActive()             [view]
  ├─► RevocationRegistry.isRevoked()       [view]
  ├─► SpendTracker.getUSDValue()           [view]
  ├─► SpendTracker.checkSpendCap()         [view]
  ├─► SpendTracker.recordSpend()           [VAULT_ROLE required]
  └─► AuditLogger.logAction()              [LOGGER_ROLE required]

PermissionVault.emergencyRevoke()
  └─► RevocationRegistry.revoke()          [REVOKER_ROLE required]
```

---

## address(0) Safety

| Contract | Check | Location |
|---|---|---|
| AgentRegistry | `require(agentWallet != address(0))` | `register()` |
| AgentRegistry | `if (rec.owner == address(0)) revert NotFound` | `updateStatus()`, `setPermissionVault()` |
| SpendTracker | `require(feedAddr != address(0))` | `_getUSDValue()` |
| PermissionVault | Implicit via `agentRegistry.resolve()` | `grantPermission()` |
| RevocationRegistry | N/A — operates on bytes32 agentId | All functions |
| AuditLogger | N/A — operates on bytes32 agentId | All functions |
