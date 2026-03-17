from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_org
from app.db import get_db
from app.models.database import Organization
from app.services.compliance import generate_compliance_report

router = APIRouter(prefix="/v1/compliance", tags=["compliance"])


@router.get("/report")
async def get_compliance_report(
    agent_id: str | None = Query(None, description="Agent DID — omit for all agents"),
    jurisdiction: str = Query("generic", pattern="^(MAS|MiCA|generic)$"),
    format: str = Query("json", pattern="^(json|csv)$"),
    date_from: datetime = Query(..., alias="from"),
    date_to: datetime = Query(..., alias="to"),
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Generate a regulatory compliance report (MAS, MiCA, or generic)."""
    report = await generate_compliance_report(
        db=db,
        org_id=org.id,
        jurisdiction=jurisdiction,
        agent_did=agent_id,
        date_from=date_from,
        date_to=date_to,
        fmt=format,
    )

    if format == "csv":
        return Response(
            content=report,
            media_type="text/csv",
            headers={"Content-Disposition": f"attachment; filename=bouclier-{jurisdiction}-report.csv"},
        )

    return report
