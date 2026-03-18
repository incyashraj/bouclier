// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IBouclier.sol";

/// @title  AuditLoggerV1
/// @notice UUPS-upgradeable version of AuditLogger.
///         Append-only tamper-evident audit log for AI agent actions.
contract AuditLoggerV1 is Initializable, UUPSUpgradeable, AccessControl, Pausable, IAuditLogger {

    bytes32 public constant LOGGER_ROLE   = keccak256("LOGGER_ROLE");
    bytes32 public constant IPFS_ROLE     = keccak256("IPFS_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    mapping(bytes32 eventId => AuditRecord)   private _records;
    mapping(bytes32 agentId => bytes32[])     private _agentHistory;
    mapping(bytes32 agentId => uint256)       private _logIndex;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address _admin) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(LOGGER_ROLE,   _admin);
        _grantRole(IPFS_ROLE,     _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    function _authorizeUpgrade(address) internal override onlyRole(UPGRADER_ROLE) {}

    // ── Logging ───────────────────────────────────────────────────

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
        uint256 logIdx = _logIndex[agentId]++;
        eventId = keccak256(abi.encode(agentId, actionHash, block.number, logIdx));
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

    function getAgentHistory(bytes32 agentId, uint256 offset, uint256 limit)
        external view returns (bytes32[] memory)
    {
        bytes32[] storage history = _agentHistory[agentId];
        uint256 total = history.length;
        if (offset >= total) return new bytes32[](0);
        uint256 end = offset + limit > total ? total : offset + limit;
        bytes32[] memory result = new bytes32[](end - offset);
        for (uint256 i = offset; i < end; i++) {
            result[i - offset] = history[i];
        }
        return result;
    }

    function getTotalEvents(bytes32 agentId) external view returns (uint256) {
        return _agentHistory[agentId].length;
    }

    // ── Pause ─────────────────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}
