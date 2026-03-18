// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "../interfaces/IBouclier.sol";

/// @title  AgentRegistryV1
/// @notice UUPS-upgradeable version of AgentRegistry.
///         Storage layout is identical to the original — safe to upgrade to.
///         The constructor is disabled; use `initialize(admin)` via ERC1967Proxy.
contract AgentRegistryV1 is Initializable, UUPSUpgradeable, AccessControl, Pausable, IAgentRegistry {

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // ── State (same layout as AgentRegistry) ──────────────────────
    mapping(bytes32 agentId => AgentRecord)          private _agents;
    mapping(address agentWallet => bytes32 agentId)  private _walletIndex;
    mapping(address owner => bytes32[])              private _ownerIndex;
    uint256 private _totalAgents;
    address public admin;

    // ── Errors ────────────────────────────────────────────────────
    error AlreadyRegistered(address agentWallet);
    error NotFound(bytes32 agentId);
    error NotOwner(bytes32 agentId, address caller);
    error ZeroAddress();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /// @notice Replaces the constructor. Called once via ERC1967Proxy.
    function initialize(address _admin) external initializer {
        if (_admin == address(0)) revert ZeroAddress();
        admin = _admin;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(UPGRADER_ROLE, _admin);
    }

    /// @notice Authorize upgrade — only UPGRADER_ROLE (held by BouclierProxyAdmin).
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {}

    // ── Registration ──────────────────────────────────────────────
    function register(
        address agentWallet,
        string  calldata model,
        bytes32 parentAgentId,
        string  calldata metadataCID
    ) external whenNotPaused returns (bytes32 agentId) {
        if (agentWallet == address(0)) revert ZeroAddress();
        if (_walletIndex[agentWallet] != bytes32(0)) revert AlreadyRegistered(agentWallet);

        uint256 nonce = _ownerIndex[msg.sender].length;
        agentId = keccak256(abi.encode(msg.sender, agentWallet, nonce));

        string memory did = _buildDID(agentWallet);

        AgentRecord storage rec = _agents[agentId];
        rec.agentAddress  = agentWallet;
        rec.owner         = msg.sender;
        rec.status        = AgentStatus.Active;
        rec.registeredAt  = uint48(block.timestamp);
        rec.agentId       = agentId;
        rec.did           = did;
        rec.model         = model;
        rec.parentAgentId = parentAgentId;
        rec.metadataCID   = metadataCID;

        _walletIndex[agentWallet]           = agentId;
        _ownerIndex[msg.sender].push(agentId);
        _totalAgents++;

        emit AgentRegistered(agentId, agentWallet, msg.sender, did, uint48(block.timestamp));
    }

    function updateStatus(bytes32 agentId, AgentStatus newStatus) external {
        AgentRecord storage rec = _agents[agentId];
        if (rec.owner == address(0)) revert NotFound(agentId);
        if (rec.owner != msg.sender && msg.sender != admin) revert NotOwner(agentId, msg.sender);
        rec.status = newStatus;
        emit AgentStatusUpdated(agentId, newStatus);
    }

    // ── Views ─────────────────────────────────────────────────────
    function resolve(bytes32 agentId) external view returns (AgentRecord memory) {
        return _agents[agentId];
    }
    function getAgentId(address agentWallet) external view returns (bytes32) {
        return _walletIndex[agentWallet];
    }
    function getAgentsByOwner(address owner) external view returns (bytes32[] memory) {
        return _ownerIndex[owner];
    }
    function isActive(bytes32 agentId) external view returns (bool) {
        return _agents[agentId].status == AgentStatus.Active;
    }
    function totalAgents() external view returns (uint256) {
        return _totalAgents;
    }
    function setPermissionVault(bytes32 agentId, address) external view {
        AgentRecord storage rec = _agents[agentId];
        if (rec.owner == address(0)) revert NotFound(agentId);
        if (rec.owner != msg.sender) revert NotOwner(agentId, msg.sender);
    }

    // ── Internal ──────────────────────────────────────────────────
    function _buildDID(address agentWallet) internal view returns (string memory) {
        string memory chainLabel = _chainLabel();
        return string(abi.encodePacked(
            "did:ethr:", chainLabel, ":0x",
            _toHex(abi.encodePacked(agentWallet))
        ));
    }
    function _chainLabel() internal view returns (string memory) {
        uint256 id = block.chainid;
        if (id == 1)     return "mainnet";
        if (id == 8453)  return "base";
        if (id == 84532) return "base-sepolia";
        if (id == 42161) return "arbitrum-one";
        return "unknown";
    }
    bytes16 private constant _HEX = "0123456789abcdef";
    function _toHex(bytes memory data) internal pure returns (string memory) {
        bytes memory result = new bytes(data.length * 2);
        for (uint256 i = 0; i < data.length; i++) {
            result[i * 2]     = _HEX[uint8(data[i]) >> 4];
            result[i * 2 + 1] = _HEX[uint8(data[i]) & 0xf];
        }
        return string(result);
    }

    // ── Pause ─────────────────────────────────────────────────────
    function pause()   external onlyRole(DEFAULT_ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) { _unpause(); }
}
