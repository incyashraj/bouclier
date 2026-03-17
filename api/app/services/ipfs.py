"""IPFS upload service via Pinata — pins JSON data and files, returns CIDs."""

import json
import logging
from typing import Any

import httpx

from app.config import get_settings

logger = logging.getLogger("bouclier.ipfs")

PINATA_API_URL = "https://api.pinata.cloud"


def _headers() -> dict[str, str]:
    """Build Pinata auth headers from settings."""
    settings = get_settings()
    return {
        "Authorization": f"Bearer {settings.pinata_jwt}",
        "Content-Type": "application/json",
    }


async def upload_json(data: dict[str, Any], name: str = "bouclier-data") -> str:
    """Pin a JSON object to IPFS via Pinata. Returns the CID (IPFS hash).

    Args:
        data: JSON-serializable dictionary to pin.
        name: Human-readable name for the pin (visible in Pinata dashboard).

    Returns:
        The IPFS CID string (e.g. "QmX...").
    """
    payload = {
        "pinataContent": data,
        "pinataMetadata": {"name": name},
        "pinataOptions": {"cidVersion": 1},
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            f"{PINATA_API_URL}/pinning/pinJSONToIPFS",
            json=payload,
            headers=_headers(),
        )
        resp.raise_for_status()
        result = resp.json()
        cid = result["IpfsHash"]
        logger.info("Pinned JSON to IPFS: %s (name=%s)", cid, name)
        return cid


async def upload_file(file_bytes: bytes, filename: str) -> str:
    """Pin a raw file to IPFS via Pinata. Returns the CID.

    Args:
        file_bytes: Raw file content.
        filename: Original filename.

    Returns:
        The IPFS CID string.
    """
    settings = get_settings()
    headers = {
        "Authorization": f"Bearer {settings.pinata_jwt}",
    }
    metadata = json.dumps({"name": filename, "keyvalues": {"source": "bouclier-api"}})

    async with httpx.AsyncClient(timeout=60) as client:
        resp = await client.post(
            f"{PINATA_API_URL}/pinning/pinFileToIPFS",
            headers=headers,
            files={"file": (filename, file_bytes)},
            data={"pinataMetadata": metadata, "pinataOptions": json.dumps({"cidVersion": 1})},
        )
        resp.raise_for_status()
        result = resp.json()
        cid = result["IpfsHash"]
        logger.info("Pinned file to IPFS: %s (filename=%s)", cid, filename)
        return cid


async def pin_cid(cid: str, name: str = "bouclier-pin") -> dict:
    """Pin an existing CID (already on the IPFS network) to Pinata.

    Args:
        cid: The IPFS CID to pin.
        name: Human-readable name.

    Returns:
        Pinata response dict with pin status.
    """
    payload = {
        "hashToPin": cid,
        "pinataMetadata": {"name": name},
    }

    async with httpx.AsyncClient(timeout=30) as client:
        resp = await client.post(
            f"{PINATA_API_URL}/pinning/pinByHash",
            json=payload,
            headers=_headers(),
        )
        resp.raise_for_status()
        result = resp.json()
        logger.info("Pinned existing CID: %s", cid)
        return result


async def get_pin_status(cid: str) -> dict | None:
    """Check if a CID is pinned on Pinata.

    Returns:
        Pin metadata dict if pinned, None otherwise.
    """
    async with httpx.AsyncClient(timeout=15) as client:
        resp = await client.get(
            f"{PINATA_API_URL}/data/pinList",
            params={"hashContains": cid, "status": "pinned", "pageLimit": 1},
            headers=_headers(),
        )
        resp.raise_for_status()
        result = resp.json()
        rows = result.get("rows", [])
        return rows[0] if rows else None
