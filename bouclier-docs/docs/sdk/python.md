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
    agent_registry      ="0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb",
    revocation_registry ="0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa",
    permission_vault    ="0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7",
    spend_tracker       ="0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1",
    audit_logger        ="0x42FDFC97CC5937E5c654dFE9494AA278A17D2735",
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
