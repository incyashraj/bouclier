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
        uint256 nonce = _ownerIndex[msg.sender].length;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000001,nonce)}
        agentId = keccak256(abi.encode(msg.sender, agentWallet, nonce));assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000f,agentId)}

        string memory did = _buildDID(agentWallet);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010002,0)}

        AgentRecord storage rec = _agents[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010003,0)}
        rec.agentAddress  = agentWallet;address certora_local16 = rec.agentAddress;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000010,certora_local16)}
        rec.owner         = msg.sender;address certora_local17 = rec.owner;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000011,certora_local17)}
        rec.status        = AgentStatus.Active;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020012,0)}
        rec.registeredAt  = uint48(block.timestamp);uint48 certora_local19 = rec.registeredAt;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000013,certora_local19)}
        rec.agentId       = agentId;bytes32 certora_local20 = rec.agentId;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000014,certora_local20)}
        rec.did           = did;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020015,0)}
        rec.model         = model;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020016,0)}
        rec.parentAgentId = parentAgentId;bytes32 certora_local23 = rec.parentAgentId;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000017,certora_local23)}
        rec.metadataCID   = metadataCID;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020018,0)}

        _walletIndex[agentWallet]           = agentId;
        _ownerIndex[msg.sender].push(agentId);
        _totalAgents++;

        emit AgentRegistered(agentId, agentWallet, msg.sender, did, uint48(block.timestamp));
    }

    // ── Mutations ─────────────────────────────────────────────────

    function updateStatus(bytes32 agentId, AgentStatus newStatus) external {
        AgentRecord storage rec = _agents[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010004,0)}
        if (rec.owner == address(0)) revert NotFound(agentId);
        if (rec.owner != msg.sender && msg.sender != admin) revert NotOwner(agentId, msg.sender);
        rec.status = newStatus;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00020019,0)}
        emit AgentStatusUpdated(agentId, newStatus);
    }

    function setPermissionVault(bytes32 agentId, address /* vault */) external view {
        AgentRecord storage rec = _agents[agentId];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010005,0)}
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
    function _buildDID(address agentWallet) internal view returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000000, 1037618708480) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00000005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00006000, agentWallet) }
        string memory chainLabel = _chainLabel();assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010006,0)}
        // Convert address to lowercase hex string
        string memory addrHex = _toHexString(agentWallet);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010007,0)}
        return string(abi.encodePacked("did:ethr:", chainLabel, ":0x", addrHex));
    }

    function _chainLabel() internal view returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010000, 1037618708481) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010001, 0) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00010004, 0) }
        uint256 id = block.chainid;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000008,id)}
        if (id == 1)     return "mainnet";
        if (id == 8453)  return "base";
        if (id == 84532) return "base-sepolia";
        if (id == 42161) return "arbitrum-one";
        if (id == 31337) return "anvil";
        // Default: numeric chain id
        return _uintToString(id);
    }

    /// @dev Convert address to 40-char lowercase hex (no leading 0x — caller adds it)
    function _toHexString(address addr) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020000, 1037618708482) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00020005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00026000, addr) }
        bytes memory buffer = new bytes(40);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00010009,0)}
        bytes memory hexChars = "0123456789abcdef";assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000a,0)}
        uint160 value = uint160(addr);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000b,value)}
        for (uint256 i = 40; i > 0; ) {
            unchecked { i--; }
            buffer[i] = hexChars[value & 0xf];bytes1 certora_local27 = buffer[i];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001b,certora_local27)}
            value >>= 4;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001c,value)}
        }
        return string(buffer);
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030000, 1037618708483) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00030005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00036000, value) }
        if (value == 0) return "0";
        uint256 temp = value;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000c,temp)}
        uint256 digits;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000000d,digits)}
        while (temp != 0) { digits++; temp /= 10;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001d,temp)} }
        bytes memory buffer = new bytes(digits);assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0001000e,0)}
        while (value != 0) {
            digits -= 1;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001e,digits)}
            uint256 digit = value % 10;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001a,digit)}
            // forge-lint: disable-next-line(unsafe-typecast) -- digit is 0-9, 48+digit fits uint8
            buffer[digits] = bytes1(uint8(48 + digit));bytes1 certora_local31 = buffer[digits];assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff0000001f,certora_local31)}
            value /= 10;assembly ("memory-safe"){mstore(0xffffff6e4604afefe123321beef1b02fffffffffffffffffffffffff00000020,value)}
        }
        return string(buffer);
    }

    // ── Emergency pause (admin only) ──────────────────────────────
    function pause()   external { require(msg.sender == admin, "not admin"); _pause(); }
    function unpause() external { require(msg.sender == admin, "not admin"); _unpause(); }
}
