# AgentRegistry.sol — Contract Architecture

> **Contract:** `AgentRegistry.sol`  
> **Layer:** Identity Layer  
> **Dependencies:** None (root contract)  
> **Used by:** `PermissionVault.sol`, `AuditLogger.sol`, SDK, Dashboard

---

## Purpose

`AgentRegistry` is the identity anchor for all AI agents in the Bouclier protocol. Every agent that wants to operate under Bouclier must first be registered here. Registration assigns:

1. A deterministic on-chain identifier (`agentId` — `bytes32` hash)
2. A W3C DID (`did:ethr:base:0xAGENT_ADDRESS`)
3. A permanent, verifiable record of who created the agent and what model it runs

This contract is intentionally minimal — it only stores identity, not permissions. Permissions live in `PermissionVault.sol`.

---

## Full Interface

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAgentRegistry {
    
    // ─────────────────────────────────────────────────────────────────
    // STRUCTS
    // ─────────────────────────────────────────────────────────────────
    
    enum AgentStatus {
        Active,
        Suspended,
        Revoked,
        Deprecated
    }
    
    struct AgentRecord {
        bytes32 agentId;          // keccak256(owner, agentAddress, nonce)
        address agentAddress;     // The wallet/smart account the agent signs with
        address owner;            // Enterprise/developer who created this agent
        string  did;              // "did:ethr:base:0x..."
        string  model;            // e.g. "claude-sonnet-4-6", "gpt-4o", "llama-4"
        bytes32 modelHash;        // sha256 of model weights (optional, for verfied models)
        string  metadataIpfsCid;  // IPFS CID of full DID document + agent metadata
        uint48  createdAt;        // block.timestamp at registration
        uint48  updatedAt;        // block.timestamp of last status change
        AgentStatus status;       // Current status
        address permissionVault;  // Address of the PermissionVault module for this agent
    }

    // ─────────────────────────────────────────────────────────────────
    // EVENTS
    // ─────────────────────────────────────────────────────────────────
    
    event AgentRegistered(
        bytes32 indexed agentId,
        address indexed agentAddress,
        address indexed owner,
        string  did,
        uint48  timestamp
    );
    
    event AgentStatusUpdated(
        bytes32 indexed agentId,
        AgentStatus previousStatus,
        AgentStatus newStatus,
        address updatedBy,
        uint48  timestamp
    );
    
    event AgentMetadataUpdated(
        bytes32 indexed agentId,
        string  newMetadataIpfsCid,
        uint48  timestamp
    );
    
    event PermissionVaultSet(
        bytes32 indexed agentId,
        address indexed permissionVault
    );

    // ─────────────────────────────────────────────────────────────────
    // WRITE FUNCTIONS
    // ─────────────────────────────────────────────────────────────────
    
    /**
     * @notice Registers a new AI agent
     * @dev Only callable by any address (permissionless — enterprise registers their own agents)
     *      The caller becomes the owner of the agent record
     * @param agentAddress  The agent's signing wallet address
     * @param model         Human-readable model identifier
     * @param modelHash     sha256 of model (bytes32(0) if not verifiable)
     * @param metadataCid   IPFS CID of the full agent DID document
     * @return agentId      Unique identifier for this agent registration
     */
    function register(
        address agentAddress,
        string calldata model,
        bytes32 modelHash,
        string calldata metadataCid
    ) external returns (bytes32 agentId);
    
    /**
     * @notice Updates the status of a registered agent
     * @dev Only callable by the agent's owner or protocol admin
     * @param agentId   The agent to update
     * @param newStatus The new status
     */
    function updateStatus(
        bytes32 agentId,
        AgentStatus newStatus
    ) external;
    
    /**
     * @notice Updates the IPFS metadata CID (e.g. when agent model is upgraded)
     * @dev Only callable by the agent's owner
     * @param agentId       The agent to update
     * @param metadataCid   New IPFS CID
     */
    function updateMetadata(
        bytes32 agentId,
        string calldata metadataCid
    ) external;
    
    /**
     * @notice Sets the PermissionVault address for an agent
     * @dev Only callable by the agent's owner
     *      Called once when PermissionVault is deployed for this agent
     * @param agentId         The agent
     * @param permissionVault Address of the deployed PermissionVault
     */
    function setPermissionVault(
        bytes32 agentId,
        address permissionVault
    ) external;

    // ─────────────────────────────────────────────────────────────────
    // READ FUNCTIONS
    // ─────────────────────────────────────────────────────────────────
    
    /**
     * @notice Resolves a DID to a full agent record
     * @param agentId  The agent identifier
     * @return record  Full AgentRecord struct
     */
    function resolve(bytes32 agentId) external view returns (AgentRecord memory record);
    
    /**
     * @notice Gets agentId from an agent wallet address
     * @param agentAddress  The agent's signing wallet
     * @return agentId      bytes32(0) if not registered
     */
    function getAgentId(address agentAddress) external view returns (bytes32 agentId);
    
    /**
     * @notice Gets all agent IDs owned by an address
     * @param owner         The owner address
     * @return agentIds     Array of all agentIds this owner has registered
     */
    function getAgentsByOwner(address owner) external view returns (bytes32[] memory agentIds);
    
    /**
     * @notice Checks if an agent is currently active (registered + not revoked/suspended)
     * @param agentId  The agent to check
     * @return active  True only if status == Active
     */
    function isActive(bytes32 agentId) external view returns (bool active);
    
    /**
     * @notice Total count of registered agents (for analytics)
     * @return count  Total registration count (including revoked)
     */
    function totalAgents() external view returns (uint256 count);
}
```

---

## Storage Layout

```solidity
// Slot layout (optimised for gas)
// Pack AgentRecord into as few storage slots as possible

mapping(bytes32 => AgentRecord) private _agents;       // agentId → record
mapping(address => bytes32) private _addressToId;      // agentAddress → agentId (reverse lookup)
mapping(address => bytes32[]) private _ownerAgents;    // owner → [agentId, ...]
uint256 private _totalAgents;                           // global counter
```

**Storage slot packing for `AgentRecord`:**

```
Slot 0: agentId (bytes32)
Slot 1: agentAddress (address, 20 bytes) + owner (address, 20 bytes) = packed? No, 40 bytes — 2 slots
        → agentAddress + status (uint8, 1 byte) + createdAt (uint48, 6 bytes) = 27 bytes → fits in 1 slot
Slot 2: owner (address, 20 bytes) + updatedAt (uint48, 6 bytes) = 26 bytes → fits in 1 slot
Slot 3: modelHash (bytes32)
Slot 4: permissionVault (address, 20 bytes) → 1 slot
Slot 5+: dynamic strings (did, model, metadataIpfsCid) stored as separate keccak slots
```

---

## agentId Derivation

```solidity
function _deriveAgentId(
    address owner,
    address agentAddress,
    uint256 nonce
) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(owner, agentAddress, nonce));
}
```

- `nonce` is the `_totalAgents` counter at time of registration
- This makes agentId deterministic but collision-resistant
- An owner can compute their agentId off-chain before the transaction

---

## DID Construction

```solidity
function _constructDID(address agentAddress) internal view returns (string memory) {
    // On Base (chainId 8453): "did:ethr:base:0x..."
    // On Arbitrum (chainId 42161): "did:ethr:arb1:0x..."
    // On Ethereum (chainId 1): "did:ethr:0x..."
    return string(abi.encodePacked(
        "did:ethr:",
        _chainPrefix(),
        ":",
        Strings.toHexString(uint256(uint160(agentAddress)), 20)
    ));
}
```

---

## Events (Full Detail)

### `AgentRegistered`
- Indexed: `agentId`, `agentAddress`, `owner`
- Emitted: once per `register()` call
- Consumed by: The Graph subgraph, dashboard activity feed, SDK `registerAgent()` confirmation

### `AgentStatusUpdated`
- Indexed: `agentId`
- Emitted: on every `updateStatus()` call
- Note: `RevocationRegistry` handles revocation — `AgentStatusUpdated` with `Revoked` status is the downstream notification

### `AgentMetadataUpdated`
- Emitted when: agent model is upgraded, DID document changes
- The Graph indexes this to keep off-chain metadata references current

---

## Access Control

```
register()           → Anyone (the caller becomes owner)
updateStatus()       → owner of agentId OR contract owner (protocol admin)
updateMetadata()     → owner of agentId only
setPermissionVault() → owner of agentId only
resolve()            → Anyone (public read)
getAgentId()         → Anyone (public read)
getAgentsByOwner()   → Anyone (public read)
isActive()           → Anyone (public read)
```

Protocol admin: timelocked 3-of-5 Gnosis Safe multisig (set at deployment, changeable with 48h timelock).

---

## Security Considerations

| Risk | Description | Mitigation |
|---|---|---|
| Agent address squatting | Register someone else's address before them | `agentAddress` must sign a typed message (EIP-712) authorising this registration |
| Metadata poisoning | Owner sets malicious IPFS CID | Metadata is informational only; enforcement never reads from IPFS |
| Owner key compromise | Attacker takes over agent record | Time-lock on critical updates; recovery mechanism via multisig |
| Infinite registration | Spam registrations bloat storage | Minimum ETH/ETH-equivalent bond per registration (configurable) |
| Centralised DID method | `did:ethr` depends on Ethereum | We ARE on Ethereum — this is a feature, not a bug |

---

## Gas Estimates

| Function | Estimated Gas |
|---|---|
| `register()` | ~85,000 (writing 5+ storage slots + events + string storage) |
| `updateStatus()` | ~30,000 (1 storage write + event) |
| `updateMetadata()` | ~50,000 (string write + event) |
| `resolve()` | ~8,000 (SLOAD × 5) |
| `isActive()` | ~3,000 (1 SLOAD) |

At Base mainnet gas prices (~0.001 gwei base), these are effectively free. Even at 10 gwei, `register()` costs ~$0.001.

---

## Test Cases Required

See [testing/testing-strategy.md](../../testing/testing-strategy.md) for full test strategy.

Key test cases for `AgentRegistry`:

```
✓ register() — successful registration, correct agentId returned
✓ register() — emits AgentRegistered event with correct args
✓ register() — reverse lookup (getAgentId) works after registration
✓ register() — DID string is correctly constructed
✓ register() — same address cannot be registered twice
✓ register() — registration without valid EIP-712 signature fails
✓ updateStatus() — owner can change status
✓ updateStatus() — non-owner cannot change status (access control)
✓ updateStatus() — status transitions valid: Active→Suspended, Active→Revoked
✓ resolve() — returns correct AgentRecord
✓ isActive() — returns false for Suspended, Revoked, Deprecated agents
✓ getAgentsByOwner() — returns all agents for an owner
✓ totalAgents() — increments correctly
✗ FUZZ: register() with random inputs never collides on agentId
✗ FUZZ: DID construction for all valid Ethereum addresses
```

---

## Deployment

```bash
# Deploy AgentRegistry (no constructor args needed)
forge script script/Deploy.s.sol:DeployAgentRegistry \
  --rpc-url $BASE_SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify deployment
cast call $AGENT_REGISTRY_ADDRESS "totalAgents()(uint256)" --rpc-url $BASE_SEPOLIA_RPC_URL
```

**Constructor arguments:** None  
**Upgradeable:** Yes (UUPS proxy pattern via OpenZeppelin)  
**Owner at deployment:** Deployer address (transferred to multisig immediately after)

---

*Last Updated: March 2026*
