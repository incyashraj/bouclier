// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ═══════════════════════════════════════════════════════════════════
//  Bouclier — Shared Types & Interfaces
//  All contracts import from this file for consistency.
// ═══════════════════════════════════════════════════════════════════

// ── ERC-4337 UserOp (v0.7 / PackedUserOperation) ─────────────────
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes   initCode;
    bytes   callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes   paymasterAndData;
    bytes   signature;
}

// ── Validation constants (ERC-7579 / ERC-4337) ────────────────────
uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED  = 1;

// ── AgentStatus ───────────────────────────────────────────────────
enum AgentStatus {
    Active,
    Suspended,
    Revoked
}

// ── RevocationReason ──────────────────────────────────────────────
enum RevocationReason {
    UserRequested,
    Suspicious,
    Compromised,
    PolicyViolation,
    Emergency
}

// ── AgentRecord (stored in AgentRegistry) ─────────────────────────
struct AgentRecord {
    address agentAddress;   // slot 0
    address owner;          // slot 0 (packed)
    AgentStatus status;     // slot 0 (packed, 1 byte)
    uint48  registeredAt;   // slot 0 (packed)
    bytes32 agentId;        // slot 1
    string  did;            // slot 2+ (dynamic)
    string  model;          // dynamic
    bytes32 parentAgentId;  // bytes32(0) = top-level agent
    string  metadataCID;    // IPFS CID of agent metadata JSON
}

// ── PermissionScope (stored in PermissionVault) ───────────────────
struct PermissionScope {
    bytes32  agentId;
    address[] allowedProtocols;    // empty = deny all (unless allowAnyProtocol)
    bytes4[]  allowedSelectors;    // empty = allow all selectors
    address[] allowedTokens;       // empty = deny all (unless allowAnyToken)
    uint256  dailySpendCapUSD;     // 18-decimal USD (0 = no cap)
    uint256  perTxSpendCapUSD;     // 18-decimal USD (0 = no cap)
    uint48   validFrom;
    uint48   validUntil;
    bool     allowAnyProtocol;
    bool     allowAnyToken;
    bool     revoked;
    bytes32  grantHash;            // EIP-712 hash of the grant, set on storage
    uint8    windowStartHour;      // 0-23, UTC (0 = no window restriction)
    uint8    windowEndHour;        // 0-23, UTC
    uint8    windowDaysMask;       // bitmask: bit0=Mon…bit6=Sun (0 = every day)
    uint64   allowedChainId;       // 0 = current chain only
}

// ── RevocationRecord (stored in RevocationRegistry) ──────────────
struct RevocationRecord {
    bool              revoked;
    uint48            revokedAt;
    uint48            reinstatedAt;
    address           revokedBy;
    RevocationReason  reason;
    string            notes;
}

// ── AuditRecord (stored in AuditLogger) ──────────────────────────
struct AuditRecord {
    bytes32 eventId;
    bytes32 agentId;
    bytes32 actionHash;
    address target;
    bytes4  selector;
    address tokenAddress;
    uint256 usdAmount;     // 18-decimal
    uint48  timestamp;
    bool    allowed;
    string  violationType; // "" if allowed
    string  ipfsCID;       // added async after on-chain log
}

// ── IAgentRegistry ───────────────────────────────────────────────
interface IAgentRegistry {
    event AgentRegistered(
        bytes32 indexed agentId,
        address indexed agentAddress,
        address indexed owner,
        string  did,
        uint48  registeredAt
    );
    event AgentStatusUpdated(bytes32 indexed agentId, AgentStatus newStatus);

    function register(
        address agentWallet,
        string  calldata model,
        bytes32 parentAgentId,
        string  calldata metadataCID
    ) external returns (bytes32 agentId);

    function resolve(bytes32 agentId) external view returns (AgentRecord memory);
    function getAgentId(address agentWallet) external view returns (bytes32);
    function getAgentsByOwner(address owner) external view returns (bytes32[] memory);
    function isActive(bytes32 agentId) external view returns (bool);
    function updateStatus(bytes32 agentId, AgentStatus newStatus) external;
    function setPermissionVault(bytes32 agentId, address vault) external;
    function totalAgents() external view returns (uint256);
}

// ── IPermissionVault ─────────────────────────────────────────────
interface IPermissionVault {
    event PermissionGranted(bytes32 indexed agentId, bytes32 indexed grantHash, uint48 validUntil);
    event PermissionRevoked(bytes32 indexed agentId, address indexed revokedBy);
    event PermissionViolation(
        bytes32 indexed agentId,
        address indexed target,
        bytes4  selector,
        string  violationType
    );

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external payable returns (uint256 validationData);

    function grantPermission(
        bytes32 agentId,
        PermissionScope calldata scope,
        bytes calldata ownerSignature
    ) external;

    function revokePermission(bytes32 agentId) external;
    function emergencyRevoke(bytes32 agentId) external;
    function getActiveScope(bytes32 agentId) external view returns (PermissionScope memory);
    function isModuleType(uint256 moduleTypeId) external view returns (bool);
    function onInstall(bytes calldata data) external;
    function onUninstall(bytes calldata data) external;
}

// ── IRevocationRegistry ──────────────────────────────────────────
interface IRevocationRegistry {
    event AgentRevoked(bytes32 indexed agentId, address indexed revokedBy, RevocationReason reason, uint48 revokedAt);
    event AgentReinstated(bytes32 indexed agentId, address indexed reinstatedBy, uint48 reinstatedAt);

    function revoke(bytes32 agentId, RevocationReason reason, string calldata notes) external;
    function batchRevoke(bytes32[] calldata agentIds, RevocationReason reason, string calldata notes) external;
    function reinstate(bytes32 agentId, string calldata notes) external;
    function isRevoked(bytes32 agentId) external view returns (bool);
    function getRevocationRecord(bytes32 agentId) external view returns (RevocationRecord memory);
}

// ── ISpendTracker ────────────────────────────────────────────────
interface ISpendTracker {
    event SpendRecorded(bytes32 indexed agentId, uint256 usdAmount, uint256 runningTotal);

    function recordSpend(bytes32 agentId, uint256 usdAmount18, uint48 timestamp) external;
    function checkSpendCap(bytes32 agentId, uint256 proposedUSD, uint256 capUSD) external view returns (bool withinCap);
    function getRollingSpend(bytes32 agentId, uint256 windowSeconds) external view returns (uint256 totalUSD);
    function getUSDValue(address token, uint256 amount) external view returns (uint256 usdValue18);
}

// ── IAuditLogger ─────────────────────────────────────────────────
interface IAuditLogger {
    event ActionLogged(
        bytes32 indexed eventId,
        bytes32 indexed agentId,
        address indexed target,
        bytes4  selector,
        bool    allowed,
        uint48  timestamp
    );
    event IPFSCIDAdded(bytes32 indexed eventId, string cid);

    function logAction(
        bytes32 agentId,
        bytes32 actionHash,
        address target,
        bytes4  selector,
        address tokenAddress,
        uint256 usdAmount,
        bool    allowed,
        string  calldata violationType
    ) external returns (bytes32 eventId);

    function addIPFSCID(bytes32 eventId, string calldata cid) external;
    function getAuditRecord(bytes32 eventId) external view returns (AuditRecord memory);
    function getAgentHistory(bytes32 agentId, uint256 offset, uint256 limit) external view returns (bytes32[] memory eventIds);
    function getTotalEvents(bytes32 agentId) external view returns (uint256);
}
