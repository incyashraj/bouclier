import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.middleware import RateLimitMiddleware, RequestIdMiddleware
from app.routes import agents, operations, platform, compliance, billing, alerts

# Structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s — %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S",
)

settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    description="Bouclier Protocol — AI Agent Permission & Compliance SaaS API",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Middleware (order matters — outermost runs first)
app.add_middleware(RequestIdMiddleware)
app.add_middleware(RateLimitMiddleware, redis_url=settings.redis_url)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://*.bouclier.xyz"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Register routes
app.include_router(agents.router)
app.include_router(operations.router)
app.include_router(compliance.router)
app.include_router(platform.router)
app.include_router(billing.router)
app.include_router(alerts.router)
