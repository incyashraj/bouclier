// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IBouclier.sol";

/// @title  AgentRegistry
/// @notice Identity anchor for AI agents. Every agent gets a unique agentId
///         and a W3C DID in the format `did:ethr:<chain>:0x<agentAddress>`.
///         Storage is packed into 3 slots per record.
contract AgentRegistry is IAgentRegistry, Pausable {
    // ── State ─────────────────────────────────────────────────────
    mapping(bytes32 agentId => AgentRecord)          private _agents;
    mapping(address agentWallet => bytes32 agentId)  private _walletIndex;
    mapping(address owner => bytes32[])              private _ownerIndex;

    uint256 private _totalAgents;

    // ── Errors ────────────────────────────────────────────────────
    error AlreadyRegistered(address agentWallet);
    error NotFound(bytes32 agentId);
    error NotOwner(bytes32 agentId, address caller);
    error ZeroAddress();

    // ── Constructor ───────────────────────────────────────────────
    address public immutable admin;

    constructor(address _admin) {
        if (_admin == address(0)) revert ZeroAddress();
        admin = _admin;
    }

    // ── Registration ──────────────────────────────────────────────

    /// @notice Register a new AI agent. Assigns a unique agentId and DID.
    /// @param agentWallet  The wallet address the agent will sign UserOps from
    /// @param model        Model identifier e.g. "claude-sonnet-4-6"
    /// @param parentAgentId bytes32(0) for top-level agents
    /// @param metadataCID  IPFS CID of agent metadata JSON (may be empty)
    function register(
        address agentWallet,
        string  calldata model,
        bytes32 parentAgentId,
        string  calldata metadataCID
    ) external whenNotPaused returns (bytes32 agentId) {
        if (agentWallet == address(0)) revert ZeroAddress();
        if (_walletIndex[agentWallet] != bytes32(0)) revert AlreadyRegistered(agentWallet);

        // Derive agentId: keccak256(owner || agentWallet || nonce)
        // nonce = current count for this owner (prevents cross-owner collisions)
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

    // ── Mutations ─────────────────────────────────────────────────

    function updateStatus(bytes32 agentId, AgentStatus newStatus) external {
        AgentRecord storage rec = _agents[agentId];
        if (rec.owner == address(0)) revert NotFound(agentId);
        if (rec.owner != msg.sender && msg.sender != admin) revert NotOwner(agentId, msg.sender);
        rec.status = newStatus;
        emit AgentStatusUpdated(agentId, newStatus);
    }

    function setPermissionVault(bytes32 agentId, address /* vault */) external view {
        AgentRecord storage rec = _agents[agentId];
        if (rec.owner == address(0)) revert NotFound(agentId);
        if (rec.owner != msg.sender) revert NotOwner(agentId, msg.sender);
        // vault address is stored off-chain (in the SaaS backend) — not needed on-chain
        // This function exists as a hook for future on-chain vault registry
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

    // ── Internal ──────────────────────────────────────────────────

    /// @dev Builds a W3C DID string: did:ethr:<chainLabel>:0x<agentAddress>
    ///      Chain labels: mainnet(1)="mainnet", base(8453)="base", arbOne(42161)="arbitrum-one"
    function _buildDID(address agentWallet) internal view returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290000, 1037618708777) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01290005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff01296000, agentWallet) }
        string memory chainLabel = _chainLabel();
        // Convert address to lowercase hex string
        string memory addrHex = _toHexString(agentWallet);
        return string(abi.encodePacked("did:ethr:", chainLabel, ":0x", addrHex));
    }

    function _chainLabel() internal view returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a0000, 1037618708778) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a0001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012a0004, 0) }
        uint256 id = block.chainid;
        if (id == 1)     return "mainnet";
        if (id == 8453)  return "base";
        if (id == 84532) return "base-sepolia";
        if (id == 42161) return "arbitrum-one";
        if (id == 31337) return "anvil";
        // Default: numeric chain id
        return _uintToString(id);
    }

    /// @dev Convert address to 40-char lowercase hex (no leading 0x — caller adds it)
    function _toHexString(address addr) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b0000, 1037618708779) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012b6000, addr) }
        bytes memory buffer = new bytes(40);
        bytes memory hexChars = "0123456789abcdef";
        uint160 value = uint160(addr);
        for (uint256 i = 40; i > 0; ) {
            unchecked { i--; }
            buffer[i] = hexChars[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012c0000, 1037618708780) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012c0001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012c0005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff012c6000, value) }
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) { digits++; temp /= 10; }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            uint256 digit = value % 10;
            // forge-lint: disable-next-line(unsafe-typecast) -- digit is 0-9, 48+digit fits uint8
            buffer[digits] = bytes1(uint8(48 + digit));
            value /= 10;
        }
        return string(buffer);
    }

    // ── Emergency pause (admin only) ──────────────────────────────
    function pause()   external { require(msg.sender == admin, "not admin"); _pause(); }
    function unpause() external { require(msg.sender == admin, "not admin"); _unpause(); }
}
