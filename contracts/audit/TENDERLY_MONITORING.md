# Bouclier — Tenderly Monitoring Setup

> **Purpose:** Real-time alerting on all critical contract events across all 5 Bouclier contracts on Base Sepolia (and later mainnet).

---

## Quick Setup

### 1. Create Tenderly Project

1. Go to https://dashboard.tenderly.co
2. Create project: **bouclier-monitoring**
3. Select network: **Base Sepolia** (chain 84532)

### 2. Add Contracts

Import all 5 contracts by address:

| Contract | Address |
|---|---|
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` |
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` |

All contracts are Basescan-verified, so Tenderly will auto-decode ABIs.

### 3. Configure Alerts

#### Critical Alerts (PagerDuty / SMS)

| Alert Name | Contract | Trigger | Severity |
|---|---|---|---|
| Agent Revoked | RevocationRegistry | `AgentRevoked(bytes32,address,uint256)` event | 🔴 Critical |
| Emergency Reinstate | RevocationRegistry | `AgentReinstated(bytes32,address,uint256)` event | 🔴 Critical |
| Permission Revoked | PermissionVault | `PermissionRevoked(bytes32,address)` event | 🔴 Critical |
| Spend Cap Exceeded | SpendTracker | `SpendCapExceeded(bytes32,uint256,uint256)` event | 🔴 Critical |
| Ownership Transferred | PermissionVault | `OwnershipTransferred(address,address)` event | 🔴 Critical |

#### High Alerts (Slack / Email)

| Alert Name | Contract | Trigger | Severity |
|---|---|---|---|
| Permission Granted | PermissionVault | `PermissionGranted(bytes32,address,uint256)` event | 🟡 High |
| Agent Registered | AgentRegistry | `AgentRegistered(bytes32,address,string)` event | 🟡 High |
| Spend Recorded | SpendTracker | `SpendRecorded(bytes32,uint256,uint256)` event | 🟡 High |
| Validation Failed | PermissionVault | `validateUserOp` returns 1 (VALIDATION_FAILED) | 🟡 High |

#### Informational Alerts (Dashboard only)

| Alert Name | Contract | Trigger | Severity |
|---|---|---|---|
| Action Logged | AuditLogger | `ActionLogged(bytes32,bytes32,uint256)` event | ℹ️ Info |
| ETH Rescued | PermissionVault | `rescueETH` function called | ℹ️ Info |

### 4. Notification Channels

| Channel | Target | Alert Levels |
|---|---|---|
| PagerDuty | On-call engineer | Critical only |
| Slack #bouclier-alerts | Engineering team | Critical + High |
| Email | founder@bouclier.xyz | All alerts |
| Tenderly Dashboard | Public | All alerts |

### 5. Web3 Actions (Optional)

Set up Tenderly Web3 Actions to auto-respond to events:

```javascript
// Auto-pause on multiple rapid revocations (possible attack)
// Trigger: 3+ AgentRevoked events within 60 seconds
const action = {
  trigger: {
    type: "event",
    contract: "RevocationRegistry",
    event: "AgentRevoked",
    condition: "count(60s) >= 3"
  },
  action: async (context, event) => {
    // Send emergency Slack notification
    await context.slack.send("#bouclier-emergency", {
      text: `🚨 ALERT: ${event.count} agents revoked in 60s. Possible attack. Check immediately.`
    });
  }
};
```

---

## Tenderly CLI Setup (Optional)

```bash
# Install Tenderly CLI
brew tap tenderly/tenderly && brew install tenderly

# Login
tenderly login

# Initialize project
cd contracts
tenderly init

# Push contracts
tenderly push --project bouclier-monitoring

# Verify all contracts are imported
tenderly contract list
```

---

## Dashboard Metrics to Track

- **Daily active agents** — Count of unique `agentId` values in transactions
- **Daily spend volume** — Sum of `SpendRecorded` amounts (USD)
- **Revocation rate** — `AgentRevoked` events per day
- **Validation failure rate** — `validateUserOp` returns 1 vs 0 ratio
- **Gas usage trends** — Average gas per `validateUserOp` call

---

*Set up Tenderly monitoring BEFORE mainnet deployment. Test all alert channels on Base Sepolia first.*
