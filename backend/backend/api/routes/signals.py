# ==========================================
# BORSA SİNYAL BACKEND - SIGNALS ROUTES
# ==========================================
from __future__ import annotations

from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from datetime import datetime, timezone, timedelta

from backend.database import get_session
from backend.models import Signal
from sqlalchemy import select, desc, func, and_

router = APIRouter()


def signal_to_dict(signal: Signal) -> dict:
    return {
        "id": signal.id,
        "date": signal.date.isoformat() if signal.date else None,
        "direction": signal.direction.value,
        "confidence": round(signal.confidence, 3),
        "components": signal.components,
        "model_version": signal.model_version,
        "created_at": signal.created_at.isoformat() if signal.created_at else None,
    }


@router.get("/")
async def get_signals(
    limit: int = Query(30, ge=1, le=100),
    offset: int = Query(0, ge=0),
    direction: Optional[str] = Query(None, pattern="^(UP|DOWN|FLAT)$"),
    days: Optional[int] = Query(None, ge=1, le=365),
):
    """Sinyal geçmişi."""
    async with get_session() as session:
        query = select(Signal)
        
        if direction:
            query = query.where(Signal.direction == direction)
        
        if days:
            since = datetime.now(timezone.utc) - timedelta(days=days)
            query = query.where(Signal.date >= since)
        
        # Toplam
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await session.execute(count_query)
        total = total_result.scalar()
        
        # Sayfalama
        query = query.order_by(desc(Signal.date)).offset(offset).limit(limit)
        result = await session.execute(query)
        signals = result.scalars().all()
        
        return {
            "signals": [signal_to_dict(s) for s in signals],
            "total": total,
            "limit": limit,
            "offset": offset,
        }


@router.get("/latest")
async def get_latest_signal():
    """En son sinyal (bugün veya en yakın tarih)."""
    async with get_session() as session:
        today = datetime.now(timezone.utc).date()
        result = await session.execute(
            select(Signal)
            .where(func.date(Signal.date) == today)
            .order_by(desc(Signal.created_at))
        )
        signal = result.scalar_one_or_none()
        
        if not signal:
            # En son sinyali getir
            result = await session.execute(
                select(Signal).order_by(desc(Signal.date)).limit(1)
            )
            signal = result.scalar_one_or_none()
        
        if not signal:
            raise HTTPException(status_code=404, detail="Henüz sinyal yok")
        
        return signal_to_dict(signal)


@router.get("/{signal_id}")
async def get_signal_detail(signal_id: str):
    """Sinyal detayı."""
    async with get_session() as session:
        result = await session.execute(
            select(Signal).where(Signal.id == signal_id)
        )
        signal = result.scalar_one_or_none()
        if not signal:
            raise HTTPException(status_code=404, detail="Sinyal bulunamadı")
        return signal_to_dict(signal)


@router.get("/stats/summary")
async def get_signal_stats(days: int = Query(30, ge=1, le=365)):
    """Sinyal istatistikleri."""
    async with get_session() as session:
        since = datetime.now(timezone.utc) - timedelta(days=days)
        
        # Yön dağılımı
        dist_result = await session.execute(
            select(Signal.direction, func.count(Signal.id))
            .where(Signal.date >= since)
            .group_by(Signal.direction)
        )
        distribution = {d.value: c for d, c in dist_result.all()}
        
        # Ortalama güven
        conf_result = await session.execute(
            select(func.avg(Signal.confidence))
            .where(Signal.date >= since)
        )
        avg_confidence = conf_result.scalar() or 0.0
        
        # Son sinyaller
        recent_result = await session.execute(
            select(Signal)
            .where(Signal.date >= since)
            .order_by(desc(Signal.date))
            .limit(10)
        )
        recent = [signal_to_dict(s) for s in recent_result.scalars().all()]
        
        return {
            "period_days": days,
            "distribution": distribution,
            "avg_confidence": round(float(avg_confidence), 3),
            "recent_signals": recent,
        }