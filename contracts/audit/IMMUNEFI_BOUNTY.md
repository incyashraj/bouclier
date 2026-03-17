# Bouclier — Immunefi Bug Bounty Program

> **Protocol:** Bouclier — The Trust Layer for Autonomous AI Agents  
> **Network:** Base (L2)  
> **Bug Bounty URL:** `https://immunefi.com/bounty/bouclier` (pending setup)  

---

## Bounty Table

| Severity | Impact | Reward (USDC) |
|---|---|---|
| **Critical** | Unauthorized bypass of `validateUserOp` for revoked agents | $50,000 |
| **Critical** | Spend cap completely bypassable (unlimited spending) | $50,000 |
| **Critical** | Unauthorized mass revocation of all agents | $25,000 |
| **High** | Partial spend cap bypass (> 10% over cap) | $10,000 |
| **High** | Audit log tampering or deletion | $10,000 |
| **High** | Signature replay (re-granting a revoked scope) | $10,000 |
| **Medium** | Front-running on `grantPermission` | $2,000 |
| **Medium** | Timelock bypass on `reinstate()` | $2,000 |
| **Low** | Denial of service (non-permanent) | $500 |

**Total bounty pool:** $100,000 USDC (multisig: 2/3 founder + 2 advisors)

---

## Assets in Scope

| Contract | Address (Base Sepolia) | Type |
|---|---|---|
| PermissionVault | `0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7` | Smart Contract |
| SpendTracker | `0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1` | Smart Contract |
| RevocationRegistry | `0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa` | Smart Contract |
| AgentRegistry | `0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb` | Smart Contract |
| AuditLogger | `0x42FDFC97CC5937E5c654dFE9494AA278A17D2735` | Smart Contract |

---

## Out of Scope

- Theoretical attacks with no practical exploitation path
- Attacks requiring compromised private keys
- Gas optimization suggestions
- Front-end / dashboard vulnerabilities
- Known issues listed in `contracts/audit/AUDIT_README.md`
- Third-party library vulnerabilities (OpenZeppelin, Chainlink)
- Testnet-only issues (e.g., faucet-related)

---

## Submission Requirements

1. **Proof of Concept** — A Foundry test (`.t.sol`) that reproduces the vulnerability
2. **Impact description** — Clear explanation of what an attacker can do
3. **Attack vector** — Step-by-step exploitation steps
4. **Suggested fix** — Recommended remediation

---

## Setup Instructions

See [AUDIT_README.md](./AUDIT_README.md) for full build/test instructions.
