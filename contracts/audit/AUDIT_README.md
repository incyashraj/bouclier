# Bouclier — Code4rena Audit Scope

> **Protocol:** Bouclier — The Trust Layer for Autonomous AI Agents on Blockchain  
> **Audit Type:** Competitive Community Audit  
> **Network:** Base Sepolia (chain 84532) — testnet. Mainnet deployment pending audit completion.  
> **Compiler:** Solidity 0.8.24, Foundry 1.5.1  

---

## Architecture Overview

Bouclier is an ERC-7579 validator module that enforces granular, cryptographically-signed permission scopes on autonomous AI agents operating on-chain. The protocol consists of 5 core contracts:

```
Human/Enterprise
       │ Permission Grant (EIP-712 signed)
       ▼
┌──────────────────────────────────────────────┐
│            BOUCLIER PROTOCOL                 │
│                                              │
│  AgentRegistry ── PermissionVault ── Audit   │
│       │                │              │      │
│  RevocationRegistry  SpendTracker  AuditLog  │
└──────────────────────────────────────────────┘
```

### Threat Model

1. **Malicious Agent** — An registered agent attempts to exceed its permission scope (access disallowed protocols, spend beyond caps, operate outside time windows).
2. **Signature Replay** — An attacker replays a valid `grantPermission` EIP-712 signature to re-grant a revoked scope.
3. **Oracle Manipulation** — Attacker manipulates the Chainlink price feed to bypass USD-denominated spend caps.
4. **Revocation Bypass** — An attacker attempts to reinstate a revoked agent before the 24-hour timelock.
5. **Reentrancy** — An attacker exploits external calls in `validateUserOp` to manipulate state.

---

## Contracts in Scope

| Contract | LoC | Complexity | Description |
|---|---|---|---|
| `src/PermissionVault.sol` | ~350 | **HIGH** | Core ERC-7579 IValidator. 15-step `validateUserOp`, EIP-712 scope granting, emergency revoke. **Primary audit target.** |
| `src/SpendTracker.sol` | ~200 | MEDIUM | Rolling-window spend tracking with Chainlink oracle. Ring buffer (MAX_ENTRIES=1000). |
| `src/RevocationRegistry.sol` | ~120 | LOW | Revocation with REVOKER_ROLE, 24h timelock for reinstatement, emergency guardian override. |
| `src/AgentRegistry.sol` | ~180 | LOW | W3C DID generation (`did:ethr:base:0x...`), agent hierarchy, status tracking. |
| `src/AuditLogger.sol` | ~150 | LOW | Immutable audit records, LOGGER_ROLE, IPFS CID support, ring buffer history. |

**Out of Scope:** Libraries (`lib/`), test files (`test/`), scripts (`script/`), off-chain SDKs, dashboard, subgraph.

---

## Known Issues / Accepted Risks

Auditors should NOT submit findings for these items:

1. **Block timestamp dependence** — `block.timestamp` is intentionally used for scope expiry (`validUntil`) and Chainlink oracle staleness checks. ±15s miner manipulation is acceptable.
2. **Chainlink single oracle** — SpendTracker uses a single Chainlink feed. A TWAP fallback is planned but not yet implemented.
3. **`rescueETH` uses low-level call** — Protected by `onlyOwner`. Required for ETH sweep to arbitrary address.
4. **`validateUserOp` is payable** — Required by ERC-4337 EntryPoint interface.
5. **Unused return values on `auditLogger.logAction()`** — Fire-and-forget audit logging. Return value intentionally ignored.

---

## Setup Instructions

```bash
# Clone the repository
git clone https://github.com/bouclier-protocol/bouclier.git
cd bouclier/contracts

# Install dependencies
forge install

# Build
forge build

# Run all tests
forge test -vvv

# Run unit tests only (76 tests)
forge test --match-path "test/unit/*" -vvv

# Run invariant tests (9 tests, 128K fuzz calls each)
forge test --match-path "test/invariant/*" -vvv

# Run integration tests (requires Base Sepolia RPC)
forge test --match-path "test/integration/*" --fork-url $BASE_SEPOLIA_RPC_URL -vvv
```

---

## Key Areas of Concern

We specifically request auditors to focus on:

1. **`PermissionVault.validateUserOp` (15-step validation)** — Can any step be bypassed? Is there an ordering attack?
2. **EIP-712 signature verification** — Can signatures be replayed across agents, chains, or after revocation?
3. **`SpendTracker` rolling window arithmetic** — Can the ring buffer be manipulated to reset spend counters?
4. **`RevocationRegistry.reinstate` 24h timelock** — Can it be bypassed via timestamp manipulation or reentrancy?
5. **Cross-contract interactions** — PermissionVault calls RevocationRegistry, SpendTracker, and AuditLogger. Are there any unexpected interaction patterns?
6. **Access control completeness** — Are there any unprotected state-changing functions?

---

## Deployed Addresses (Base Sepolia)

| Contract | Address |
|---|---|
| AgentRegistry | `0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB` |
| RevocationRegistry | `0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270` |
| PermissionVault | `0xe0b283A4Dff684E5D700E53900e7B27279f7999F` |
| SpendTracker | `0x930Eb18B9962c30b388f900ba9AE62386191cD48` |
| AuditLogger | `0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE` |

---

## Documentation

- [Architecture Docs](../../architecture/)
- [EIP Draft](../../docs/eip-draft-agent-permission-validator.md)
- [Standards Gap Analysis](../../docs/standards/)
- [Security Report (internal)](./SECURITY_REPORT.md)
- [Docusaurus Docs Site](https://bouclier-docs-nzoz4sbma-incyashrajs-projects.vercel.app)

---

## Contact

For questions during the audit, reach out via:
- GitHub Issues: `https://github.com/bouclier-protocol/bouclier/issues`
- Discord: (link TBD)
