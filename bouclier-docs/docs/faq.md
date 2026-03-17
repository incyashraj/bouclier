---
sidebar_position: 10
---

# FAQ

## General

### What is Bouclier?

Bouclier is an open-source on-chain trust layer for AI agents. It lets you define cryptographically-enforced permission scopes for agents — what protocols they can call, what tokens they can spend, how much per day — and provides a tamper-proof audit trail of everything they do.

### Why on-chain instead of off-chain rules?

Off-chain rules can be bypassed, tampered with, or lost. An on-chain permission scope is a contract — it cannot be modified by the agent itself, and the audit log is immutable by design. This matters for regulators, enterprise compliance teams, and anyone who needs to prove what an agent did (or didn't do).

### What chains do you support?

Base Sepolia is live now. Base mainnet, Arbitrum One, and Ethereum mainnet are planned for Phase 4.

---

## SDK

### Does the SDK make on-chain calls for every `checkPermission`?

No. `checkPermission` is a read-only simulation that reads contract state locally — it costs no gas and makes a single `eth_call`. Only `grantPermission`, `revokeAgent`, and `registerAgent` are write transactions.

### Can I use the SDK without a wallet (read-only mode)?

Yes. Omit `walletClient` from the constructor. You can call all read functions (`isRevoked`, `getActiveScope`, `getAuditTrail`, `getAgentId`) without a wallet.

### What version of viem does the TypeScript SDK require?

viem v2 (`>=2.0.0`). The SDK is fully typed against viem's type system.

### Is the Python SDK async?

The current `BouclierClient` is synchronous. An `AsyncBouclierClient` using `asyncio` is planned for v0.2.

---

## Contracts

### What happens if an agent tries to call a contract not in the allowlist?

`validateUserOp` returns `SIG_VALIDATION_FAILED` (1) and emits a `PermissionViolation` event with `violationType = "PROTOCOL_NOT_ALLOWED"`. The ERC-4337 EntryPoint reverts the user operation.

### Can an agent modify its own permission scope?

No. `grantPermission` and `revokePermission` can only be called by the **owner** of the agent (the wallet that registered it). The agent's own wallet has no ability to change its scope.

### How fast is revoking an agent?

Instant — one transaction to `RevocationRegistry.revoke()`. The next `validateUserOp` call will call `isRevoked()` and return `SIG_VALIDATION_FAILED` in the same block. It costs ≤ 50,000 gas.

### What is the 24-hour reinstatement timelock?

After revoking, the owner must wait 24 hours before reinstating the agent. This prevents a compromised owner account from immediately un-revoking a malicious agent. `GUARDIAN_ROLE` holders can bypass this for genuine emergencies.

---

## Integrations

### Does Bouclier work with OpenAI Assistants API?

Not natively yet. The LangChain adapter covers OpenAI models running through LangChain's `ChatOpenAI`. Native Assistants API support is on the roadmap.

### Can I use Bouclier with CrewAI?

The Python SDK includes a `BouclierGuard` tool wrapper that works with CrewAI agents. See the [Python SDK docs](./sdk/python).

### Does the ELIZA plugin work with ElizaOS v2?

Yes. `@bouclier/eliza-plugin` targets the `@elizaos/core` Plugin interface which is compatible with ElizaOS v1 and v2.

---

## Security

### Has Bouclier been audited?

Not yet. Phase 3 (planned) targets a Code4rena community audit and Certora formal verification of `validateUserOp`, `checkSpendCap`, and `isRevoked`.

### Can the Chainlink oracle be manipulated to bypass spend caps?

Bouclier uses a **maximum of 1 hour stale data** check — if oracle data is older than 3600 seconds, the transaction reverts. Flash loan price manipulation within a single block does not affect the USD conversion since the oracle price is from an external heartbeat feed, not an AMM.

### Is the AuditLogger truly append-only?

Yes. There is no `update` or `delete` function. The `invariant_auditRecordsImmutable` Echidna property validates this at the protocol level.  
