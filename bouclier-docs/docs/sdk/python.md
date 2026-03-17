---
sidebar_position: 2
---

# Python SDK

`bouclier-sdk` is the Python client for the Bouclier protocol. It uses [web3.py 7](https://web3py.readthedocs.io) and [pydantic v2](https://docs.pydantic.dev).

```bash
pip install bouclier-sdk
```

---

## Initialisation

```python
from bouclier import BouclierClient

client = BouclierClient(
    rpc_url="https://base-sepolia.g.alchemy.com/v2/YOUR_KEY",
    agent_registry      ="0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB",
    revocation_registry ="0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270",
    permission_vault    ="0xe0b283A4Dff684E5D700E53900e7B27279f7999F",
    spend_tracker       ="0x930Eb18B9962c30b388f900ba9AE62386191cD48",
    audit_logger        ="0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE",
    # optional — needed for write calls
    private_key="0xYourPrivateKey",
)
```

---

## API Reference

### `register_agent`

```python
result = client.register_agent(
    agent_wallet="0xAgentWallet",
    model="claude-3-5",
    parent_agent_id=None,
    metadata_cid="",
)
print(result.agent_id)
```

### `grant_permission`

```python
from bouclier.models import PermissionScope
from web3 import Web3

scope = PermissionScope(
    allowed_protocols=["0xUniswapRouter"],
    allowed_tokens=["0xUSDC"],
    allowed_selectors=["0x414bf389"],
    per_tx_spend_cap_usd=Web3.to_wei(100, "ether"),   # $100
    daily_spend_cap_usd=Web3.to_wei(500, "ether"),    # $500
    valid_from=int(time.time()),
    valid_until=int(time.time()) + 86400 * 30,
    allow_any_protocol=False,
    allow_any_token=False,
)

tx_hash = client.grant_permission(agent_id=agent_id, scope=scope)
```

### `check_permission`

```python
from bouclier.models import ActionRequest

result = client.check_permission(
    agent_id=agent_id,
    action=ActionRequest(
        target="0xUniswapRouter",
        selector="0x414bf389",
        token_address="0xUSDC",
        estimated_value_usd=Web3.to_wei(50, "ether"),
    ),
)

if not result.allowed:
    print("Blocked:", result.reason)
```

### `revoke_agent`

```python
client.revoke_agent(agent_id=agent_id, notes="Anomaly detected")
```

### `is_revoked`

```python
revoked: bool = client.is_revoked(agent_id)
```

### `get_audit_trail`

```python
events = client.get_audit_trail(agent_id, limit=20, offset=0)
for event in events:
    print(event.event_id, event.target, event.usd_amount)
```

---

## LangChain Integration

```python
from bouclier.langchain import BouclierCallbackHandler
from langchain.agents import AgentExecutor

handler = BouclierCallbackHandler(client=client, agent_id=agent_id)
executor = AgentExecutor(agent=agent, tools=tools, callbacks=[handler])
```

---

## Testing without a live chain

```python
from bouclier.testing import MockBouclierClient, MockScope

client = MockBouclierClient(
    default_scope=MockScope(
        daily_spend_cap_usd=500,
        allowed_protocols=["0xUniswap"],
    )
)
```

`MockBouclierClient` has the same interface as `BouclierClient` but returns configurable in-memory responses. All 9 pytest tests use this pattern.

---

## Requirements

- Python ≥ 3.12
- `web3>=7.0.0`
- `eth-account>=0.13.0`
- `pydantic>=2.0.0`
