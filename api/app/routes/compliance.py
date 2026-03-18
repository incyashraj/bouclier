from datetime import datetime
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Response
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.auth import get_current_org
from app.db import get_db
from app.models.database import Organization, ReportSchedule
from app.services.compliance import generate_compliance_report

router = APIRouter(prefix="/v1/compliance", tags=["compliance"])


@router.get("/report")
async def get_compliance_report(
    agent_id: str | None = Query(None, description="Agent DID — omit for all agents"),
    jurisdiction: str = Query("generic", pattern="^(MAS|MiCA|generic)$"),
    format: str = Query("json", pattern="^(json|csv|pdf)$"),
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

    if format == "pdf":
        return Response(
            content=report,
            media_type="application/pdf",
            headers={"Content-Disposition": f"attachment; filename=bouclier-{jurisdiction}-report.pdf"},
        )

    return report


# ── Report Scheduling (Item 9) ────────────────────────────────────────────────

VALID_JURISDICTIONS = {"MAS", "MiCA", "generic"}
VALID_FORMATS = {"json", "csv", "pdf"}


class ScheduleCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    jurisdiction: str = Field("generic")
    format: str = Field("pdf")
    cron: str = Field(..., description="5-part cron expression (UTC), e.g. '0 8 * * 1'")
    delivery_email: str | None = Field(None, description="Email address to deliver report to")
    agent_id: str | None = Field(None, description="null = all agents in org")


class ScheduleResponse(BaseModel):
    id: uuid.UUID
    name: str
    jurisdiction: str
    format: str
    cron: str
    delivery_email: str | None
    agent_id: str | None
    is_active: bool
    last_run_at: datetime | None
    next_run_at: datetime | None
    created_at: datetime


def _validate_cron(expr: str) -> None:
    """Basic 5-part cron format validation."""
    parts = expr.strip().split()
    if len(parts) != 5:
        raise HTTPException(
            status_code=422,
            detail={"code": "INVALID_CRON", "message": "Cron must be a 5-part expression (min hour dom month dow)"},
        )


@router.post("/schedules", response_model=ScheduleResponse, status_code=201)
async def create_report_schedule(
    body: ScheduleCreate,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Create a scheduled compliance report (runs according to the cron expression)."""
    if body.jurisdiction not in VALID_JURISDICTIONS:
        raise HTTPException(status_code=422, detail={"code": "INVALID_JURISDICTION", "valid": sorted(VALID_JURISDICTIONS)})
    if body.format not in VALID_FORMATS:
        raise HTTPException(status_code=422, detail={"code": "INVALID_FORMAT", "valid": sorted(VALID_FORMATS)})
    _validate_cron(body.cron)

    schedule = ReportSchedule(
        organization_id=org.id,
        name=body.name,
        jurisdiction=body.jurisdiction,
        format=body.format,
        cron=body.cron,
        delivery_email=body.delivery_email,
        agent_id=body.agent_id,
    )
    db.add(schedule)
    await db.commit()
    await db.refresh(schedule)

    return _to_response(schedule)


@router.get("/schedules", response_model=list[ScheduleResponse])
async def list_report_schedules(
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """List all scheduled reports for this organization."""
    result = await db.execute(
        select(ReportSchedule)
        .where(ReportSchedule.organization_id == org.id)
        .order_by(ReportSchedule.created_at.desc())
    )
    return [_to_response(s) for s in result.scalars().all()]


@router.delete("/schedules/{schedule_id}", status_code=204)
async def delete_report_schedule(
    schedule_id: uuid.UUID,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Delete a scheduled report."""
    result = await db.execute(
        select(ReportSchedule)
        .where(ReportSchedule.id == schedule_id, ReportSchedule.organization_id == org.id)
    )
    schedule = result.scalar_one_or_none()
    if not schedule:
        raise HTTPException(status_code=404, detail={"code": "SCHEDULE_NOT_FOUND"})
    await db.delete(schedule)
    await db.commit()


@router.patch("/schedules/{schedule_id}/toggle", response_model=ScheduleResponse)
async def toggle_report_schedule(
    schedule_id: uuid.UUID,
    org: Organization = Depends(get_current_org),
    db: AsyncSession = Depends(get_db),
):
    """Enable or disable a scheduled report."""
    result = await db.execute(
        select(ReportSchedule)
        .where(ReportSchedule.id == schedule_id, ReportSchedule.organization_id == org.id)
    )
    schedule = result.scalar_one_or_none()
    if not schedule:
        raise HTTPException(status_code=404, detail={"code": "SCHEDULE_NOT_FOUND"})
    schedule.is_active = not schedule.is_active
    await db.commit()
    await db.refresh(schedule)
    return _to_response(schedule)


def _to_response(s: ReportSchedule) -> ScheduleResponse:
    return ScheduleResponse(
        id=s.id, name=s.name, jurisdiction=s.jurisdiction, format=s.format,
        cron=s.cron, delivery_email=s.delivery_email, agent_id=s.agent_id,
        is_active=s.is_active, last_run_at=s.last_run_at, next_run_at=s.next_run_at,
        created_at=s.created_at,
    )
