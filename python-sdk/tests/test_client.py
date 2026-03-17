"""Unit tests for BouclierClient — uses unittest.mock to avoid real RPC calls."""

from __future__ import annotations

import time
from unittest.mock import MagicMock, patch

import pytest
from bouclier_sdk import BouclierClient, Addresses, AgentStatus
from bouclier_sdk.types import GrantScopeParams

MOCK_ADDRESSES = Addresses(
    agent_registry      = "0x" + "1" * 40,
    revocation_registry = "0x" + "2" * 40,
    spend_tracker       = "0x" + "3" * 40,
    audit_logger        = "0x" + "4" * 40,
    permission_vault    = "0x" + "5" * 40,
)

MOCK_AGENT_ID  = "0x" + "aa" * 32
MOCK_AGENT_WALLET = "0x" + "bb" * 20
MOCK_OWNER        = "0x" + "cc" * 20

# ── Fixture ──────────────────────────────────────────────────────────────────

@pytest.fixture
def client():
    with patch("bouclier_sdk.client.Web3") as MockWeb3:
        instance = MockWeb3.return_value
        instance.eth.chain_id = 84532
        instance.eth.get_transaction_count.return_value = 0

        # Mock each contract call to return predictable data
        mock_contract = MagicMock()
        instance.eth.contract.return_value = mock_contract
        instance.isConnected.return_value = True

        c = BouclierClient(
            rpc_url   = "https://sepolia.base.org",
            addresses = MOCK_ADDRESSES,
        )
        c._mock_contract = mock_contract
        yield c


# ── AgentRecord mapping ───────────────────────────────────────────────────────

def test_resolve_agent_maps_correctly(client: BouclierClient):
    raw_return = (
        bytes.fromhex("aa" * 32),  # agentId
        MOCK_OWNER,                 # owner
        MOCK_AGENT_WALLET,          # agentWallet
        "did:ethr:base-sepolia:0xbbbb...",
        "claude-3-5-sonnet",
        "QmTestCID",
        bytes(32),                  # parentAgentId (zero)
        1_710_000_000,              # registeredAt
        0,                          # status = ACTIVE
        1,                          # nonce
    )
    client._agent_reg.functions.resolve.return_value.call.return_value = raw_return  # type: ignore

    record = client.resolve_agent(MOCK_AGENT_ID)

    assert record.model           == "claude-3-5-sonnet"
    assert record.status          == AgentStatus.ACTIVE
    assert record.owner           == MOCK_OWNER
    assert record.nonce           == 1


def test_is_revoked_returns_false_when_clean(client: BouclierClient):
    client._rev_reg.functions.isRevoked.return_value.call.return_value = False  # type: ignore
    assert client.is_revoked(MOCK_AGENT_ID) is False


def test_is_revoked_returns_true_when_revoked(client: BouclierClient):
    client._rev_reg.functions.isRevoked.return_value.call.return_value = True  # type: ignore
    assert client.is_revoked(MOCK_AGENT_ID) is True


def test_get_rolling_spend_returns_uint(client: BouclierClient):
    client._spend.functions.getRollingSpend.return_value.call.return_value = 50 * 10**18  # type: ignore
    result = client.get_rolling_spend(MOCK_AGENT_ID)
    assert result == 50 * 10**18


def test_check_spend_cap_within_returns_true(client: BouclierClient):
    client._spend.functions.checkSpendCap.return_value.call.return_value = True  # type: ignore
    assert client.check_spend_cap(MOCK_AGENT_ID, 50 * 10**18, 100 * 10**18) is True


def test_check_spend_cap_exceeded_returns_false(client: BouclierClient):
    client._spend.functions.checkSpendCap.return_value.call.return_value = False  # type: ignore
    assert client.check_spend_cap(MOCK_AGENT_ID, 150 * 10**18, 100 * 10**18) is False


def test_total_agents_returns_count(client: BouclierClient):
    client._agent_reg.functions.totalAgents.return_value.call.return_value = 42  # type: ignore
    assert client.total_agents() == 42


def test_b32_pads_short_hex():
    c = BouclierClient.__new__(BouclierClient)
    result = c._b32("0xaa")
    assert len(result) == 32
    assert result[-1] == 0xAA


def test_write_without_private_key_raises(client: BouclierClient):
    params = GrantScopeParams(
        agent_id             = MOCK_AGENT_ID,
        daily_spend_cap_usd  = 1000 * 10**18,
        per_tx_spend_cap_usd = 100  * 10**18,
    )
    with pytest.raises(ValueError, match="private_key is required"):
        client.grant_permission(params)
