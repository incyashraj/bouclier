// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IBouclier.sol";

/// @title  AuditLogger
/// @notice Append-only, tamper-evident audit log for AI agent actions.
///         Phase 1: synchronous on-chain hash. Phase 2: async IPFS CID added via `addIPFSCID`.
///         INVARIANT: records are never modified after the initial log — only `ipfsCID` is added.
contract AuditLogger is IAuditLogger, AccessControl, Pausable {
    // ── Roles ─────────────────────────────────────────────────────
    bytes32 public constant LOGGER_ROLE = keccak256("LOGGER_ROLE"); // PermissionVault
    bytes32 public constant IPFS_ROLE   = keccak256("IPFS_ROLE");   // Backend API

    // ── State ─────────────────────────────────────────────────────
    mapping(bytes32 eventId => AuditRecord)   private _records;
    mapping(bytes32 agentId => bytes32[])     private _agentHistory;

    // Per-agent log index tracks the current logging index (used in eventId derivation)
    mapping(bytes32 agentId => uint256) private _logIndex;

    // ── Constructor ───────────────────────────────────────────────
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LOGGER_ROLE, admin); // PermissionVault will be granted this role on deploy
        _grantRole(IPFS_ROLE,   admin);
    }

    // ── Logging ───────────────────────────────────────────────────

    /// @notice Log an agent action.  Only callable by PermissionVault (LOGGER_ROLE).
    ///         Returns a unique eventId. The eventId is deterministic given the inputs.
    function logAction(
        bytes32 agentId,
        bytes32 actionHash,
        address target,
        bytes4  selector,
        address tokenAddress,
        uint256 usdAmount,
        bool    allowed,
        string  calldata violationType
    ) external onlyRole(LOGGER_ROLE) whenNotPaused returns (bytes32 eventId) {
        uint256 logIdx = _logIndex[agentId]++;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,logIdx)}

        // eventId = keccak256(agentId || actionHash || block.number || logIndex)
        eventId = keccak256(abi.encode(agentId, actionHash, block.number, logIdx));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000006,eventId)}

        // Detect collision (astronomically unlikely, but guard it)
        require(_records[eventId].timestamp == 0, "AuditLogger: eventId collision");

        _records[eventId] = AuditRecord({
            eventId:       eventId,
            agentId:       agentId,
            actionHash:    actionHash,
            target:        target,
            selector:      selector,
            tokenAddress:  tokenAddress,
            usdAmount:     usdAmount,
            timestamp:     uint48(block.timestamp),
            allowed:       allowed,
            violationType: violationType,
            ipfsCID:       ""
        });

        _agentHistory[agentId].push(eventId);

        emit ActionLogged(eventId, agentId, target, selector, allowed, uint48(block.timestamp));
    }

    /// @notice Add an IPFS CID to an existing record (Phase 2 async step).
    ///         Only callable by the backend API (IPFS_ROLE).
    ///         Only the `ipfsCID` field is mutable — all other fields are sealed.
    function addIPFSCID(bytes32 eventId, string calldata cid) external onlyRole(IPFS_ROLE) {
        require(_records[eventId].timestamp != 0, "AuditLogger: record not found");
        require(bytes(_records[eventId].ipfsCID).length == 0, "AuditLogger: CID already set");
        _records[eventId].ipfsCID = cid;
        emit IPFSCIDAdded(eventId, cid);
    }

    // ── Views ─────────────────────────────────────────────────────

    function getAuditRecord(bytes32 eventId) external view returns (AuditRecord memory) {
        return _records[eventId];
    }

    function getAgentHistory(
        bytes32 agentId,
        uint256 offset,
        uint256 limit
    ) external view returns (bytes32[] memory eventIds) {
        bytes32[] storage history = _agentHistory[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010002,0)}
        uint256 total = history.length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000003,total)}
        if (offset >= total) return new bytes32[](0);

        uint256 end = offset + limit;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000004,end)}
        if (end > total) end = total;
        uint256 resultLen = end - offset;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000005,resultLen)}

        eventIds = new bytes32[](resultLen);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020007,0)}
        for (uint256 i; i < resultLen; ++i) {
            eventIds[i] = history[offset + i];bytes32 certora_local8 = eventIds[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,certora_local8)}
        }
    }

    function getTotalEvents(bytes32 agentId) external view returns (uint256) {
        return _agentHistory[agentId].length;
    }

    // ── Emergency pause ───────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}
