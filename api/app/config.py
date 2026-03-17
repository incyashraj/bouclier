from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    app_name: str = "Bouclier API"
    version: str = "0.1.0"
    debug: bool = False

    # Database
    database_url: str = "postgresql+asyncpg://bouclier:bouclier@localhost:5432/bouclier"

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # Auth
    api_key_prefix_live: str = "bsk_live_"
    api_key_prefix_test: str = "bsk_test_"
    jwt_secret: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60

    # Blockchain
    base_sepolia_rpc_url: str = "https://sepolia.base.org"
    base_mainnet_rpc_url: str = "https://mainnet.base.org"
    arbitrum_rpc_url: str = "https://arb1.arbitrum.io/rpc"

    # Contract addresses (Base Sepolia defaults)
    agent_registry_address: str = "0xc5288F059A1eCDb5E8957fC5c17E86754B7850fb"
    permission_vault_address: str = "0xff3107529d7815ea6FAAba2b3EfC257538D0Fbb7"
    spend_tracker_address: str = "0xA0bb860Ae111DbD0C174e7c8FA17495FcE9534e1"
    revocation_registry_address: str = "0xCBa8C42E7e69DB1746b0DCE4BF6Cd58d52c8e0aa"
    audit_logger_address: str = "0x42FDFC97CC5937E5c654dFE9494AA278A17D2735"

    # The Graph
    subgraph_url: str = "https://api.studio.thegraph.com/query/1744498/bouclier-base-sepolia/v0.0.1"

    # IPFS / Pinata
    pinata_jwt: str = ""
    pinata_gateway: str = "https://gateway.pinata.cloud/ipfs"

    # Alerts
    slack_webhook_url: str = ""
    discord_webhook_url: str = ""

    # Rate limiting
    rate_limit_pro: int = 100  # req/min
    rate_limit_enterprise: int = 1000  # req/min

    model_config = {"env_file": ".env", "env_prefix": "BOUCLIER_"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
