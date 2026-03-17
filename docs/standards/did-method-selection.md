# DID Method Selection — Why `did:ethr` for Bouclier

> **Standard:** [W3C DID Core v1.0](https://www.w3.org/TR/did-core/)  
> **Method Used:** `did:ethr` ([spec](https://github.com/decentralized-identity/ethr-did-resolver))  
> **Analyst:** Bouclier Protocol  
> **Date:** 2026-03-18  
> **Status:** Complete

---

## What Is a DID in Bouclier?

Every AI agent registered with Bouclier gets a **Decentralized Identifier (DID)** — a globally unique, persistent identifier controlled by the agent's owner, not by Bouclier.

When `AgentRegistry.register(agentWallet, model, parentAgentId, metadataCID)` is called:
1. An `agentId` is derived: `keccak256(abi.encode(owner, agentWallet, nonce))`
2. A DID string is generated: `did:ethr:base:0x{agentWallet_lowercase_40_hex}`
3. Both are stored in the `AgentRecord` struct

Example:
```
agentId: 0x3f4a8b1c...  (bytes32, internal identifier)
did:     did:ethr:base:0xabc123def456...  (string, external identifier)
```

---

## DID Method Comparison

| Method | On-chain? | Updatable? | Trust Model | Complexity | Right for Bouclier? |
|---|---|---|---|---|---|
| `did:ethr` | Yes (Ethereum) | Yes (key rotation via ethr-did-registry) | Ethereum PKI | Low | ✅ **Chosen** |
| `did:key` | No (self-contained) | No (key = ID) | Self-sovereign | Minimal | ❌ Not updatable |
| `did:web` | No (DNS) | Yes | DNS + TLS | Low | ❌ DNS = centralized |
| `did:ion` | Yes (Bitcoin) | Yes | Bitcoin PoW | Very High | ❌ Wrong chain |
| `did:pkh` | No (account) | No | Account sig | Minimal | ❌ No key rotation |
| `did:ens` | Yes (Ethereum) | Yes | ENS registry | Medium | ❌ Requires ENS name |

---

## Why `did:ethr`

### 1. Ethereum-native — Same Trust Root as Our Contracts

`did:ethr` identifiers are controlled by the Ethereum private key that corresponds to the address in the DID. For `did:ethr:base:0xabc…`:
- Controller = owner of `0xabc…`
- This is the same key that owns `AgentRecord.agentWallet`
- No additional key infrastructure required

### 2. Key Rotation Support

`did:ethr` supports key rotation via the `EthereumDIDRegistry` contract (deployed at a fixed address on all major networks). An agent can rotate its signing keys without changing its DID.

**Bouclier v1 does not use key rotation** (out of scope), but having a DID method that supports it future-proofs the architecture.

### 3. Chain-scoped Format

The `did:ethr` method supports chain namespaces:
```
did:ethr:base:0x...        ← Base mainnet (chain ID 8453)
did:ethr:base-sepolia:0x…  ← Base Sepolia testnet (chain ID 84532)
did:ethr:mainnet:0x…       ← Ethereum mainnet (chain ID 1)
```

Bouclier uses `did:ethr:base:0x…` on Base mainnet and `did:ethr:base-sepolia:0x…` on testnet. The deploy script sets the network name correctly.

### 4. Resolved by ethr-did-resolver (TypeScript)

The `ethr-did-resolver` npm package resolves `did:ethr` identifiers to DID Documents. Bouclier's TypeScript SDK can resolve agent DIDs without any custom resolver infrastructure.

```typescript
import { EthrDIDDocument } from 'ethr-did-resolver';
// resolve did:ethr:base:0x... → { id, controller, verificationMethod[] }
```

### 5. W3C DID Core Compliance

`did:ethr` is fully compliant with W3C DID Core v1.0:
- DID Document includes `verificationMethod` (Ethereum address as secp256k1 key)
- `authentication` references the controller's key
- `service` endpoints can be added (future: Bouclier API endpoint)

---

## DID Format in AgentRegistry

```solidity
// In AgentRegistry._generateDID(address agentWallet):
string memory networkId = _getNetworkId(); // "base" or "base-sepolia"
string memory hexAddr = _toHexString(uint256(uint160(agentWallet)), 20);
return string(abi.encodePacked("did:ethr:", networkId, ":0x", hexAddr));
```

**Note on casing:** The `did:ethr` spec requires the hex address to be **lowercase** (not EIP-55 checksum). `AgentRegistry._toHexString` outputs lowercase hex. This is intentional and correct per the ethr-did spec.

---

## DID Document Structure (Resolved)

When a DID is resolved via `ethr-did-resolver`, the resulting DID Document for `did:ethr:base:0xabc…` looks like:

```json
{
  "@context": ["https://www.w3.org/ns/did/v1"],
  "id": "did:ethr:base:0xabc...",
  "verificationMethod": [
    {
      "id": "did:ethr:base:0xabc...#controllerKey",
      "type": "EcdsaSecp256k1RecoveryMethod2020",
      "controller": "did:ethr:base:0xabc...",
      "blockchainAccountId": "eip155:8453:0xabc..."
    }
  ],
  "authentication": ["did:ethr:base:0xabc...#controllerKey"],
  "assertionMethod": ["did:ethr:base:0xabc...#controllerKey"]
}
```

---

## Phase 2 Extensions

- **`did:ethr` service endpoints:** Add a `service` entry pointing to a Bouclier API endpoint for off-chain audit trail queries
- **Verifiable Credentials:** Issue a VC (`type: BouclierPermissionScope`) referencing the agent's DID, signed by the owner's DID. This provides a W3C-compliant record of permission grants usable in MAS compliance reports.
- **DID rotation for compromised agents:** If an agent wallet is compromised, the owner can rotate via `EthereumDIDRegistry.changeOwner()` without losing the DID history.

---

## Summary

`did:ethr` was chosen because it is Ethereum-native (same trust root as Bouclier's smart contracts), supports key rotation, provides chain-scoped namespacing for multi-chain deployments, and is resolvable by widely-adopted TypeScript tooling. The DID format `did:ethr:base:0x{address}` is implemented in `AgentRegistry._generateDID()` with lowercase hex per spec.
