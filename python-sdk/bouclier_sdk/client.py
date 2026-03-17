"""BouclierClient — main Python interface to the Bouclier protocol."""

from __future__ import annotations

import time
from typing import Optional

from eth_account import Account
from eth_account.messages import encode_typed_data
from web3 import Web3
from web3.contract import Contract

from .abis import (
    AGENT_REGISTRY_ABI,
    PERMISSION_VAULT_ABI,
    REVOCATION_REGISTRY_ABI,
    SPEND_TRACKER_ABI,
    AUDIT_LOGGER_ABI,
)
from .types import (
    Addresses,
    AgentRecord,
    AgentStatus,
    AuditRecord,
    GrantScopeParams,
    PermissionScope,
    RevocationRecord,
)

ONE_DAY_SECONDS = 86_400
E18 = 10**18


class BouclierClient:
    """
    Python client for the Bouclier AI Agent Trust Layer.

    Supports both read-only (no private_key) and read-write modes.

    Args:
        rpc_url:     HTTP/WS RPC endpoint (e.g. https://sepolia.base.org)
        addresses:   Deployed contract addresses (Addresses model)
        private_key: Optional hex private key for write operations
    """

    def __init__(
        self,
        rpc_url: str,
        addresses: Addresses,
        private_key: Optional[str] = None,
    ) -> None:
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.addresses  = addresses
        self._account   = Account.from_key(private_key) if private_key else None

        self._agent_reg  = self._contract(addresses.agent_registry,      AGENT_REGISTRY_ABI)
        self._vault      = self._contract(addresses.permission_vault,     PERMISSION_VAULT_ABI)
        self._rev_reg    = self._contract(addresses.revocation_registry,  REVOCATION_REGISTRY_ABI)
        self._spend      = self._contract(addresses.spend_tracker,        SPEND_TRACKER_ABI)
        self._audit      = self._contract(addresses.audit_logger,         AUDIT_LOGGER_ABI)

    # ── AgentRegistry ────────────────────────────────────────────────────────

    def resolve_agent(self, agent_id: str) -> AgentRecord:
        """Resolve a bytes32 agentId to a full AgentRecord."""
        raw = self._agent_reg.functions.resolve(self._b32(agent_id)).call()
        return AgentRecord(
            agent_id       = raw[0].hex() if isinstance(raw[0], bytes) else raw[0],
            owner          = raw[1],
            agent_wallet   = raw[2],
            did            = raw[3],
            model          = raw[4],
            metadata_cid   = raw[5],
            parent_agent_id= raw[6].hex() if isinstance(raw[6], bytes) else raw[6],
            registered_at  = raw[7],
            status         = AgentStatus(raw[8]),
            nonce          = raw[9],
        )

    def get_agent_id(self, agent_wallet: str) -> str:
        """Reverse lookup: agent wallet address → bytes32 agentId."""
        result = self._agent_reg.functions.getAgentId(
            Web3.to_checksum_address(agent_wallet)
        ).call()
        return result.hex() if isinstance(result, bytes) else result

    def get_agents_by_owner(self, owner: str) -> list[str]:
        """Return all agentIds registered under owner."""
        results = self._agent_reg.functions.getAgentsByOwner(
            Web3.to_checksum_address(owner)
        ).call()
        return [r.hex() if isinstance(r, bytes) else r for r in results]

    def is_agent_active(self, agent_id: str) -> bool:
        return self._agent_reg.functions.isActive(self._b32(agent_id)).call()

    def total_agents(self) -> int:
        return self._agent_reg.functions.totalAgents().call()

    def register_agent(
        self,
        agent_wallet: str,
        model: str,
        parent_agent_id: str = "0x" + "0" * 64,
        metadata_cid: str = "",
    ) -> str:
        """
        Register a new agent on-chain.
        Returns the transaction hash. Requires private_key.
        """
        self._require_account()
        tx = self._agent_reg.functions.register(
            Web3.to_checksum_address(agent_wallet),
            model,
            self._b32(parent_agent_id),
            metadata_cid,
        ).build_transaction(self._tx_opts())
        return self._send(tx)

    # ── RevocationRegistry ────────────────────────────────────────────────────

    def is_revoked(self, agent_id: str) -> bool:
        return self._rev_reg.functions.isRevoked(self._b32(agent_id)).call()

    def get_revocation_record(self, agent_id: str) -> RevocationRecord:
        raw = self._rev_reg.functions.getRevocationRecord(self._b32(agent_id)).call()
        return RevocationRecord(
            agent_id      = raw[0].hex() if isinstance(raw[0], bytes) else raw[0],
            revoked_at    = raw[1],
            reason        = raw[2],
            notes         = raw[3],
            revoked_by    = raw[4],
            reinstated    = raw[5],
            reinstate_after = raw[6],
        )

    # ── PermissionVault ───────────────────────────────────────────────────────

    def get_active_scope(self, agent_id: str) -> PermissionScope:
        """Read the active PermissionScope for an agent."""
        raw = self._vault.functions.getActiveScope(self._b32(agent_id)).call()
        return PermissionScope(
            agent_id              = raw[0].hex() if isinstance(raw[0], bytes) else raw[0],
            allowed_protocols     = list(raw[1]),
            allowed_selectors     = [s.hex() if isinstance(s, bytes) else s for s in raw[2]],
            allowed_tokens        = list(raw[3]),
            daily_spend_cap_usd   = raw[4],
            per_tx_spend_cap_usd  = raw[5],
            valid_from            = raw[6],
            valid_until           = raw[7],
            allow_any_protocol    = raw[8],
            allow_any_token       = raw[9],
            revoked               = raw[10],
            grant_hash            = raw[11].hex() if isinstance(raw[11], bytes) else raw[11],
            window_start_hour     = raw[12],
            window_end_hour       = raw[13],
            window_days_mask      = raw[14],
            allowed_chain_id      = raw[15],
        )

    def grant_nonce(self, agent_id: str) -> int:
        return self._vault.functions.grantNonces(self._b32(agent_id)).call()

    def grant_permission(self, params: GrantScopeParams) -> str:
        """
        Build an EIP-712 signed scope and call grantPermission on-chain.
        Requires private_key (the agent owner's key).
        Returns the transaction hash.
        """
        self._require_account()

        now          = int(time.time())
        valid_from   = now
        valid_until  = now + params.valid_for_days * ONE_DAY_SECONDS
        daily        = params.daily_spend_cap_usd
        per_tx       = params.per_tx_spend_cap_usd
        nonce        = self.grant_nonce(params.agent_id)
        chain_id     = self.w3.eth.chain_id
        agent_id_b32 = self._b32(params.agent_id)

        # EIP-712 structured data
        typed_data = {
            "domain": {
                "name":              "BouclierPermissionVault",
                "version":           "1",
                "chainId":           chain_id,
                "verifyingContract": Web3.to_checksum_address(self.addresses.permission_vault),
            },
            "types": {
                "EIP712Domain": [
                    {"name": "name",              "type": "string"},
                    {"name": "version",           "type": "string"},
                    {"name": "chainId",           "type": "uint256"},
                    {"name": "verifyingContract", "type": "address"},
                ],
                "PermissionScope": [
                    {"name": "agentId",           "type": "bytes32"},
                    {"name": "nonce",             "type": "uint256"},
                    {"name": "dailySpendCapUSD",  "type": "uint256"},
                    {"name": "perTxSpendCapUSD",  "type": "uint256"},
                    {"name": "validFrom",         "type": "uint48"},
                    {"name": "validUntil",        "type": "uint48"},
                    {"name": "allowAnyProtocol",  "type": "bool"},
                    {"name": "allowAnyToken",     "type": "bool"},
                ],
            },
            "primaryType": "PermissionScope",
            "message": {
                "agentId":           agent_id_b32,
                "nonce":             nonce,
                "dailySpendCapUSD":  daily,
                "perTxSpendCapUSD":  per_tx,
                "validFrom":         valid_from,
                "validUntil":        valid_until,
                "allowAnyProtocol":  params.allow_any_protocol,
                "allowAnyToken":     params.allow_any_token,
            },
        }

        signed = self._account.sign_typed_data(  # type: ignore[union-attr]
            domain_data=typed_data["domain"],
            message_types={"PermissionScope": typed_data["types"]["PermissionScope"]},
            message_data=typed_data["message"],
        )

        scope_tuple = (
            agent_id_b32,
            [Web3.to_checksum_address(p) for p in params.allowed_protocols],
            [],                             # allowedSelectors — empty = all
            [Web3.to_checksum_address(t) for t in params.allowed_tokens],
            daily,
            per_tx,
            valid_from,
            valid_until,
            params.allow_any_protocol,
            params.allow_any_token,
            False,                          # revoked
            b"\x00" * 32,                   # grantHash
            0,                              # windowStartHour
            0,                              # windowEndHour
            0,                              # windowDaysMask
            0,                              # allowedChainId
        )

        tx = self._vault.functions.grantPermission(
            agent_id_b32,
            scope_tuple,
            signed.signature,
        ).build_transaction(self._tx_opts())
        return self._send(tx)

    def revoke_permission(self, agent_id: str) -> str:
        """Soft-revoke the active scope for an agent. Requires private_key."""
        self._require_account()
        tx = self._vault.functions.revokePermission(
            self._b32(agent_id)
        ).build_transaction(self._tx_opts())
        return self._send(tx)

    # ── SpendTracker ────────────────────────────────────────────────────────

    def get_rolling_spend(self, agent_id: str, window_seconds: int = ONE_DAY_SECONDS) -> int:
        """Return rolling spend in 18-decimal USD."""
        return self._spend.functions.getRollingSpend(
            self._b32(agent_id), window_seconds
        ).call()

    def check_spend_cap(self, agent_id: str, proposed_usd: int, cap_usd: int) -> bool:
        return self._spend.functions.checkSpendCap(
            self._b32(agent_id), proposed_usd, cap_usd
        ).call()

    # ── AuditLogger ─────────────────────────────────────────────────────────

    def get_total_events(self, agent_id: str) -> int:
        return self._audit.functions.getTotalEvents(self._b32(agent_id)).call()

    def get_audit_trail(self, agent_id: str, offset: int = 0, limit: int = 50) -> list[AuditRecord]:
        """Return the most recent audit records for an agent."""
        event_ids = self._audit.functions.getAgentHistory(
            self._b32(agent_id), offset, limit
        ).call()

        records = []
        for eid in event_ids:
            raw = self._audit.functions.getAuditRecord(eid).call()
            records.append(AuditRecord(
                event_id       = raw[0].hex() if isinstance(raw[0], bytes) else raw[0],
                agent_id       = raw[1].hex() if isinstance(raw[1], bytes) else raw[1],
                action_hash    = raw[2].hex() if isinstance(raw[2], bytes) else raw[2],
                target         = raw[3],
                selector       = raw[4].hex() if isinstance(raw[4], bytes) else raw[4],
                token_address  = raw[5],
                usd_amount     = raw[6],
                timestamp      = raw[7],
                allowed        = raw[8],
                violation_type = raw[9],
                ipfs_cid       = raw[10],
            ))
        return records

    # ── Internal helpers ─────────────────────────────────────────────────────

    def _contract(self, address: str, abi: list) -> Contract:
        return self.w3.eth.contract(
            address=Web3.to_checksum_address(address),
            abi=abi,
        )

    def _b32(self, hex_str: str) -> bytes:
        """Convert 0x-prefixed hex string to 32-byte bytes."""
        s = hex_str[2:] if hex_str.startswith("0x") else hex_str
        return bytes.fromhex(s.zfill(64))

    def _tx_opts(self) -> dict:
        assert self._account is not None
        return {
            "from":  self._account.address,
            "nonce": self.w3.eth.get_transaction_count(self._account.address),
            "gas":   500_000,
        }

    def _send(self, tx: dict) -> str:
        assert self._account is not None
        signed_tx = self._account.sign_transaction(tx)
        tx_hash = self.w3.eth.send_raw_transaction(signed_tx.raw_transaction)
        return tx_hash.hex()

    def _require_account(self) -> None:
        if self._account is None:
            raise ValueError(
                "BouclierClient: private_key is required for write operations"
            )
