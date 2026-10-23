# ==========================================
# BORSA SİNYAL BACKEND - SYSTEM ROUTES
# ==========================================
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional

from backend.config import get_settings
from backend.scheduler import SignalScheduler
from backend.main import scheduler

router = APIRouter()


class RetrainRequest(BaseModel):
    force: bool = False


class RetrainResponse(BaseModel):
    status: str
    message: str
    metrics: Optional[dict] = None


@router.get("/status")
async def system_status():
    """Sistem durumu."""
    settings = get_settings()
    return {
        "app_name": settings.app_name,
        "version": "2.0.0",
        "environment": settings.app_env,
        "scheduler_running": scheduler._running if scheduler else False,
        "fetch_interval_minutes": settings.fetch_interval_minutes,
        "model_path": settings.model_path,
        "database_url": settings.database_url.split("@")[-1] if "@" in settings.database_url else settings.database_url,
    }


@router.post("/retrain", response_model=RetrainResponse)
async def retrain_model(request: RetrainRequest):
    """Modeli yeniden eğit."""
    if not scheduler:
        raise HTTPException(status_code=503, detail="Scheduler not running")
    
    try:
        result = await scheduler.retrain_model()
        return RetrainResponse(
            status="success",
            message="Model yeniden eğitildi",
            metrics=result,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Eğitim hatası: {str(e)}")


@router.post("/fetch")
async def manual_fetch():
    """Manuel veri çekme tetikle."""
    if not scheduler:
        raise HTTPException(status_code=503, detail="Scheduler not running")
    
    result = await scheduler.manual_fetch()
    return {"status": "completed", "result": result}


@router.post("/generate-signal")
async def manual_generate_signal():
    """Manuel sinyal üretimi tetikle."""
    if not scheduler:
        raise HTTPException(status_code=503, detail="Scheduler not running")
    
    await scheduler.generate_daily_signal()
    return {"status": "completed", "message": "Günlük sinyal üretildi"}


@router.get("/settings")
async def get_settings_api():
    """Mevcut ayarları getir (hassas bilgiler hariç)."""
    settings = get_settings()
    return {
        "fetch_interval_minutes": settings.fetch_interval_minutes,
        "signal_threshold": settings.signal_threshold,
        "cleanup_interval_hours": settings.cleanup_interval_hours,
        "max_news_age_days": settings.max_news_age_days,
        "model_version": settings.model_version,
        "retrain_interval_hours": settings.retrain_interval_hours,
        "min_training_samples": settings.min_training_samples,
        "positive_keywords_count": len(settings.parsed_positive_keywords),
        "negative_keywords_count": len(settings.parsed_negative_keywords),
        "rss_feeds_count": len(settings.parsed_rss_feeds),
        "youtube_channels_count": len(settings.parsed_youtube_channels),
    }