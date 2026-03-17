# bouclier-sdk (Python)

Python client for the [Bouclier AI Agent Trust Layer](https://github.com/bouclier/bouclier).

## Install

```bash
pip install bouclier-sdk
# or
uv add bouclier-sdk
```

## Quick Start

```python
from bouclier_sdk import BouclierClient, Addresses, GrantScopeParams

# Read-only client (no private key)
client = BouclierClient(
    rpc_url   = "https://sepolia.base.org",
    addresses = Addresses(
        agent_registry      = "0x...",
        revocation_registry = "0x...",
        spend_tracker       = "0x...",
        audit_logger        = "0x...",
        permission_vault    = "0x...",
    ),
)

agent_id = client.get_agent_id("0xAgentWallet")
record   = client.resolve_agent(agent_id)
scope    = client.get_active_scope(agent_id)
spend    = client.get_rolling_spend(agent_id)  # 18-decimal USD
events   = client.get_audit_trail(agent_id, limit=20)

# Write operations (requires private key)
client_rw = BouclierClient(
    rpc_url     = "https://sepolia.base.org",
    addresses   = addresses,
    private_key = "0x...",
)

tx_hash = client_rw.grant_permission(GrantScopeParams(
    agent_id             = agent_id,
    daily_spend_cap_usd  = 1000 * 10**18,   # $1,000/day
    per_tx_spend_cap_usd = 100  * 10**18,   # $100/tx
    valid_for_days       = 30,
    allow_any_protocol   = True,
    allow_any_token      = True,
))
```

## Development

```bash
cd python-sdk
pip install -e ".[dev]"
pytest
```
