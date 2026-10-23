# ==========================================
# BORSA SİNYAL BACKEND - NEWS ROUTES
# ==========================================
from __future__ import annotations

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List
from datetime import datetime, timedelta, timezone

from backend.database import get_session
from backend.models import NewsItem, NewsSource
from sqlalchemy import select, desc, or_, func, and_

router = APIRouter()


def item_to_dict(item: NewsItem, include_content: bool = False) -> dict:
    d = {
        "id": item.id,
        "source_id": item.source_id,
        "title": item.title,
        "summary": item.summary,
        "url": item.url,
        "author": item.author,
        "tags": item.tags,
        "published_at": item.published_at.isoformat() if item.published_at else None,
        "fetched_at": item.fetched_at.isoformat() if item.fetched_at else None,
        "processed_at": item.processed_at.isoformat() if item.processed_at else None,
        "sentiment_score": item.sentiment_score,
        "relevant_tickers": item.relevant_tickers,
    }
    if include_content:
        d["content"] = item.content
    return d


def source_to_dict(source: NewsSource) -> dict:
    return {
        "id": source.id,
        "name": source.name,
        "type": source.type.value,
        "url": source.url,
        "enabled": source.enabled,
        "weight": source.weight,
        "config": source.config,
        "created_at": source.created_at.isoformat() if source.created_at else None,
        "updated_at": source.updated_at.isoformat() if source.updated_at else None,
        "last_fetched_at": source.last_fetched_at.isoformat() if source.last_fetched_at else None,
        "last_error": source.last_error,
    }


@router.get("/latest")
async def get_latest_news(
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
    source_id: Optional[str] = Query(None),
    category: Optional[str] = Query(None),
    sentiment_min: Optional[float] = Query(None, ge=-1, le=1),
    sentiment_max: Optional[float] = Query(None, ge=-1, le=1),
    ticker: Optional[str] = Query(None),
    hours: Optional[int] = Query(None, ge=1, le=168),
):
    """En son haberleri getir (filtreli)."""
    async with get_session() as session:
        query = select(NewsItem).where(NewsItem.processed_at.is_not(None))
        
        # Filtreler
        if source_id:
            query = query.where(NewsItem.source_id == source_id)
        
        if category:
            query = query.where(NewsItem.tags.contains([category]))
        
        if sentiment_min is not None:
            query = query.where(NewsItem.sentiment_score >= sentiment_min)
        
        if sentiment_max is not None:
            query = query.where(NewsItem.sentiment_score <= sentiment_max)
        
        if ticker:
            query = query.where(NewsItem.relevant_tickers.contains([ticker.upper()]))
        
        if hours:
            since = datetime.now(timezone.utc) - timedelta(hours=hours)
            query = query.where(NewsItem.fetched_at >= since)
        
        # Toplam sayı
        count_query = select(func.count()).select_from(query.subquery())
        total_result = await session.execute(count_query)
        total = total_result.scalar()
        
        # Sayfalama
        query = query.order_by(desc(NewsItem.published_at)).offset(offset).limit(limit)
        result = await session.execute(query)
        items = result.scalars().all()
        
        return {
            "items": [item_to_dict(item) for item in items],
            "total": total,
            "limit": limit,
            "offset": offset,
        }


@router.get("/{news_id}")
async def get_news_detail(news_id: str):
    """Haber detayı."""
    async with get_session() as session:
        result = await session.execute(
            select(NewsItem).where(NewsItem.id == news_id)
        )
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Haber bulunamadı")
        return item_to_dict(item, include_content=True)


@router.get("/related")
async def get_related_news(
    exclude_id: str = Query(...),
    tickers: Optional[str] = Query(None),
    limit: int = Query(10, ge=1, le=50),
):
    """İlgili haberler (ticker bazlı)."""
    async with get_session() as session:
        query = select(NewsItem).where(
            NewsItem.id != exclude_id,
            NewsItem.processed_at.is_not(None),
        )
        
        if tickers:
            ticker_list = [t.strip().upper() for t in tickers.split(",")]
            conditions = [NewsItem.relevant_tickers.contains([t]) for t in ticker_list]
            query = query.where(or_(*conditions))
        
        query = query.order_by(desc(NewsItem.published_at)).limit(limit)
        result = await session.execute(query)
        items = result.scalars().all()
        
        return [item_to_dict(item) for item in items]


@router.get("/stats/summary")
async def get_news_stats(
    hours: int = Query(24, ge=1, le=168),
):
    """Haber istatistikleri."""
    async with get_session() as session:
        since = datetime.now(timezone.utc) - timedelta(hours=hours)
        
        # Toplam haber
        total_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
            )
        )
        total = total_result.scalar()
        
        # Kaynak bazlı
        source_result = await session.execute(
            select(NewsSource.name, func.count(NewsItem.id))
            .join(NewsItem, NewsSource.id == NewsItem.source_id)
            .where(NewsItem.fetched_at >= since, NewsItem.processed_at.is_not(None))
            .group_by(NewsSource.name)
        )
        by_source = dict(source_result.all())
        
        # Sentiment dağılımı
        pos_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score > 0.1,
            )
        )
        positive = pos_result.scalar()
        
        neg_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score < -0.1,
            )
        )
        negative = neg_result.scalar()
        
        neu_result = await session.execute(
            select(func.count(NewsItem.id)).where(
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score >= -0.1,
                NewsItem.sentiment_score <= 0.1,
            )
        )
        neutral = neu_result.scalar()
        
        # Ortalama sentiment
        avg_result = await session.execute(
            select(func.avg(NewsItem.sentiment_score)).where(
                NewsItem.fetched_at >= since,
                NewsItem.processed_at.is_not(None),
                NewsItem.sentiment_score.is_not(None),
            )
        )
        avg_sentiment = avg_result.scalar() or 0.0
        
        return {
            "period_hours": hours,
            "total": total,
            "by_source": by_source,
            "sentiment": {
                "positive": positive,
                "negative": negative,
                "neutral": neutral,
                "average": round(float(avg_sentiment), 4),
            },
        }


# Source CRUD
@router.get("/sources")
async def list_sources():
    """Tüm kaynakları listele."""
    async with get_session() as session:
        result = await session.execute(select(NewsSource).order_by(NewsSource.name))
        sources = result.scalars().all()
        return [source_to_dict(s) for s in sources]


@router.post("/sources")
async def create_source(source_data: dict):
    """Yeni kaynak ekle."""
    from backend.models import SourceType
    import uuid
    
    async with get_session() as session:
        source = NewsSource(
            id=str(uuid.uuid4()),
            name=source_data["name"],
            type=SourceType(source_data["type"]),
            url=source_data["url"],
            enabled=source_data.get("enabled", True),
            weight=source_data.get("weight", 0.8),
            config=source_data.get("config", {}),
        )
        session.add(source)
        await session.commit()
        await session.refresh(source)
        return source_to_dict(source)


@router.patch("/sources/{source_id}")
async def update_source(source_id: str, source_data: dict):
    """Kaynak güncelle."""
    async with get_session() as session:
        result = await session.execute(
            select(NewsSource).where(NewsSource.id == source_id)
        )
        source = result.scalar_one_or_none()
        if not source:
            raise HTTPException(status_code=404, detail="Kaynak bulunamadı")
        
        for key, value in source_data.items():
            if key == "type":
                value = SourceType(value)
            setattr(source, key, value)
        
        source.updated_at = datetime.now(timezone.utc)
        await session.commit()
        await session.refresh(source)
        return source_to_dict(source)


@router.delete("/sources/{source_id}")
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


@router.post("/sources/{source_id}/test")
async def test_source(source_id: str):
    """Kaynağı test et (tek seferlik fetch)."""
    from backend.fetchers import RSSFetcher, YouTubeFetcher, KAPFetcher
    from backend.models import SourceType
    
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
                "items": [item_to_dict(item) for item in items[:5]],
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}
        finally:
            if hasattr(fetcher, 'close'):
                await fetcher.close()