# ==========================================
# BORSA SİNYAL BACKEND - SOURCES ROUTES
# ==========================================
from __future__ import annotations

from fastapi import APIRouter, Query, HTTPException, Body
from typing: Optional, List
from datetime import datetime, timezone
import uuid

from backend.database import get_session
from backend.models import NewsSource, NewsItem, SourceType
from sqlalchemy import select, desc, func, and_

from backend.api.routes.news import source_to_dict

router = APIRouter()


@router.get("/")
async def list_sources(enabled_only: bool = Query(False)):
    """Tüm kaynakları listele."""
    async with get_session() as session:
        query = select(NewsSource).order_by(NewsSource.name)
        if enabled_only:
            query = query.where(NewsSource.enabled == True)
        result = await session.execute(query)
        sources = result.scalars().all()
        return [source_to_dict(s) for s in sources]


@router.post("/")
async def create_source(source_data: dict = Body(...)):
    """Yeni kaynak ekle."""
    async with get_session() as session:
        # Validasyon
        required = ["name", "type", "url"]
        for field in required:
            if field not in source_data:
                raise HTTPException(status_code=400, detail=f"Eksik alan: {field}")
        
        try:
            source_type = SourceType(source_data["type"])
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Geçersiz kaynak tipi: {source_data['type']}")
        
        source = NewsSource(
            id=str(uuid.uuid4()),
            name=source_data["name"],
            type=source_type,
            url=source_data["url"],
            enabled=source_data.get("enabled", True),
            weight=source_data.get("weight", 0.8),
            config=source_data.get("config", {}),
        )
        session.add(source)
        await session.commit()
        await session.refresh(source)
        return source_to_dict(source)


@router.get("/{source_id}")
async def get_source(source_id: str):
    """Kaynak detayı."""
    async with get_session() as session:
        result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        return source_to_dict(source)


@router.patch("/{source_id}")
async def update_source(source_id: str, source_data: dict = Body(...)):
    """Kaynak güncelle."""
    async with get_session() as session:
        result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        
        allowed_fields = ["name", "type", "url", "enabled", "weight", "config"]
        for key, value in source_data.items():
            if key not in allowed_fields:
                continue
            if key == "type":
                try:
                    value = SourceType(value)
                except ValueError:
                    raise HTTPException(status_code=400, detail=f"Geçersiz kaynak tipi: {value}")
            setattr(source, key, value)
        
        source.updated_at = datetime.now(timezone.utc)
        await session.commit()
        await session.refresh(source)
        return source_to_dict(source)


@router.delete("/{source_id}")
async def delete_source(source_id: str):
    """Kaynak sil."""
    async with get_session() as session:
        result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        
        await session.delete(source)
        await session.commit()
        return {"status": "deleted", "id": source_id}


@router.post("/{source_id}/toggle")
async def toggle_source(source_id: str):
    """Kaynak aktif/pasif."""
    async with get_session() as session:
        result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        
        source.enabled = not source.enabled
        source.updated_at = datetime.now(timezone.utc)
        await session.commit()
        await session.refresh(source)
        return source_to_dict(source)


@router.get("/{source_id}/stats")
async def get_source_stats(source_id: str, days: int = Query(7, ge=1, le=30)):
    """Kaynak istatistikleri."""
    async with get_session() as session:
        # Kaynak var mı?
        src_result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = src_result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        
        since = datetime.now(timezone.utc) - timedelta(days=days)
        
        # Toplam haber
        total_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.source_id == source_id,
                NewsItem.fetched_at >= since,
            )
        )
        total = total_result.scalar()
        
        # İşlenmiş haber
        processed_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.source_id == source_id,
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
            )
        )
        processed = processed_result.scalar()
        
        # Sentiment dağılımı
        pos_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.source_id == source_id,
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score > 0.1,
            )
        )
        positive = pos_result.scalar()
        
        neg_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.source_id == source_id,
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score < -0.1,
            )
        )
        negative = neg_result.scalar()
        
        # Ortalama sentiment
        avg_result = await session.execute(
            select(func.avg(NewsItem.sentiment_score)).where(
                NewsItem.source_id == source_id,
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score.is_not(None),
            )
        )
        avg_sentiment = avg_result.scalar() or 0.0
        
        # Son fetch
        last_fetch = source.last_fetched_at.isoformat() if source.last_fetched_at else None
        
        return {
            "source_id": source_id,
            "source_name": source.name,
            "period_days": days,
            "total_fetched": total,
            "processed": processed,
            "processing_rate": round(processed / total, 3) if total > 0 else 0,
            "sentiment": {
                "positive": positive,
                "negative": negative,
                "neutral": processed - positive - negative,
                "average": round(float(avg_sentiment), 4),
            },
            "last_fetched_at": last_fetch,
            "last_error": source.last_error,
        }


@router.post("/{source_id}/test")
async def test_source(source_id: str):
    """Kaynağı test et (tek seferlik fetch)."""
    from backend.fetchers import RSSFetcher, YouTubeFetcher, KAPFetcher
    from backend.api.routes.news import item_to_dict
    
    async with get_session() as session:
        result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        
        fetcher_map = {
            SourceType.RSS: RSSFetcher(),
            SourceType.YOUTUBE: YouTubeFetcher(),
            SourceType.KAP: KAPFetcher(),
        }
        
        fetcher = fetcher_map.get(source.type)
        if not fetcher:
            raise HTTPException(status_code=400, detail=f"Desteklenmeyen kaynak tipi: {source.type}")
        
        try:
            items = await fetcher.fetch(source)
            return {
                "status": "success",
                "fetched_count": len(items),
                "items": [item_to_dict(item) for item in items[:10]],
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
        finally:
            if hasattr(fetcher, 'close'):
                await fetcher.close()


@router.post("/bulk-import")
async def bulk_import_sources(sources: List[dict] = Body(...)):
    """Toplu kaynak içe aktar (JSON)."""
    created = []
    errors = []
    
    for i, src in enumerate(sources):
        try:
            result = await create_source(src)
            created.append(result)
        except Exception as e:
            errors.append({"index": i, "error": str(e), "data": src})
    
    return {"created": len(created), "errors": len(errors), "details": {"created": created, "errors": errors}}