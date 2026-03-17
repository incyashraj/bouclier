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
| AgentRegistry | `0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB` |
| RevocationRegistry | `0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270` |
| PermissionVault | `0xe0b283A4Dff684E5D700E53900e7B27279f7999F` |
| SpendTracker | `0x930Eb18B9962c30b388f900ba9AE62386191cD48` |
| AuditLogger | `0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE` |

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
