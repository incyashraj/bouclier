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
    agent_registry_address: str = "0x4b23841a1CD67B1489d6d84d2dCe666ddeF4CcDB"
    permission_vault_address: str = "0xe0b283A4Dff684E5D700E53900e7B27279f7999F"
    spend_tracker_address: str = "0x930Eb18B9962c30b388f900ba9AE62386191cD48"
    revocation_registry_address: str = "0x759833B7eEA1Df45ad2b2f22b56bee6CC5227270"
    audit_logger_address: str = "0x8E30A7eC6Ba7c767535b0e178e002d354F7335cE"

    # The Graph
    subgraph_url: str = "https://api.studio.thegraph.com/query/1744498/bouclier-base-sepolia/v0.0.1"

    # IPFS / Pinata
    pinata_jwt: str = ""
    pinata_gateway: str = "https://gateway.pinata.cloud/ipfs"

    # Alerts
    slack_webhook_url: str = ""
    discord_webhook_url: str = ""

    # Stripe
    stripe_secret_key: str = ""
    stripe_webhook_secret: str = ""
    stripe_price_growth: str = ""      # Stripe Price ID for Growth tier
    stripe_price_enterprise: str = ""  # Stripe Price ID for Enterprise tier

    # Rate limiting
    rate_limit_pro: int = 100  # req/min
    rate_limit_enterprise: int = 1000  # req/min

    model_config = {"env_file": ".env", "env_prefix": "BOUCLIER_"}


@lru_cache
def get_settings() -> Settings:
    return Settings()
