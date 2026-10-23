# ==========================================
# BORSA SİNYAL BACKEND - ANA GİRİŞ NOKTASI
# ==========================================
from __future__ import annotations

import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from backend.config import get_settings
from backend.database import init_db, close_db
from backend.scheduler import SignalScheduler

# API Routes
from backend.api.routes import news, technical, market, signals, sources, system

# Logging ayarı
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)
logger = logging.getLogger(__name__)

# Global scheduler instance
scheduler: SignalScheduler | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Uygulama başlangıç/kapanış yaşam döngüsü."""
    global scheduler
    
    # Başlangıç
    logger.info("🚀 Borsa Sinyal Backend başlatılıyor...")
    
    # Veritabanı init
    await init_db()
    logger.info("✅ Veritabanı hazır")
    
    # Scheduler başlat
    scheduler = SignalScheduler()
    await scheduler.start()
    logger.info("✅ Zamanlayıcı başlatıldı")
    
    # Model yükle
    from backend.nlp.model import SignalModel
    model = SignalModel()
    model.load()
    logger.info("✅ Model yüklendi")
    
    yield
    
    # Kapanış
    logger.info("🛑 Borsa Sinyal Backend kapatılıyor...")
    if scheduler:
        await scheduler.stop()
    await close_db()
    logger.info("✅ Temizlik tamamlandı")


def create_app() -> FastAPI:
    """FastAPI uygulaması oluştur."""
    settings = get_settings()
    
    app = FastAPI(
        title="Borsa Sinyal API",
        description="BIST haber + teknik analiz tabanlı sinyal API'si",
        version="2.0.0",
        lifespan=lifespan,
        docs_url="/docs" if settings.debug else None,
        redoc_url="/redoc" if settings.debug else None,
    )
    
    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.parsed_cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # API Routes
    app.include_router(system.router, prefix="/api/v1")
    app.include_router(news.router, prefix="/api/v1/news", tags=["news"])
    app.include_router(technical.router, prefix="/api/v1/technical", tags=["technical"])
    app.include_router(market.router, prefix="/api/v1/market", tags=["market"])
    app.include_router(signals.router, prefix="/api/v1/signals", tags=["signals"])
    app.include_router(sources.router, prefix="/api/v1/sources", tags=["sources"])
    
    # Health check
    @app.get("/health")
    async def health_check():
        return {
            "status": "healthy",
            "version": "2.0.0",
            "scheduler_running": scheduler._running if scheduler else False,
        }
    
    # Root
    @app.get("/")
    async def root():
        return {
            "name": "Borsa Sinyal API",
            "version": "2.0.0",
            "docs": "/docs",
            "health": "/health",
        }
    
    return app


app = create_app()


if __name__ == "__main__":
    import uvicorn
    settings = get_settings()
    uvicorn.run(
        "backend.main:app",
        host=settings.api_host,
        port=settings.api_port,
        reload=settings.debug,
        workers=settings.api_workers,
    )