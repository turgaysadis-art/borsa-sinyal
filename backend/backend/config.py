# ==========================================
# BORSA SİNYAL BACKEND - KONFIGÜRASYON
# ==========================================
from __future__ import annotations

import os
from functools import lru_cache
from typing: List

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )
    
    # Uygulama
    app_name: str = "borsa-sinyal"
    app_env: str = "development"
    debug: bool = True
    log_level: str = "INFO"
    
    # API
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    api_workers: int = 1
    
    # Veritabanı
    database_url: str = "sqlite+aiosqlite:///./data/borsa_signal.db"
    
    # Redis
    redis_url: str = "redis://localhost:6379/0"
    
    # KAP
    kap_api_key: str = ""
    kap_base_url: str = "https://api.kap.org.tr/v1"
    
    # YouTube
    youtube_api_key: str = ""
    youtube_channels: str = ""
    
    # RSS Feed'ler
    rss_feeds: str = ""
    
    # Model
    model_path: str = "./models/signal_model.joblib"
    vectorizer_path: str = "./models/tfidf_vectorizer.joblib"
    model_version: str = "v2.0.0"
    retrain_interval_hours: int = 24
    min_training_samples: int = 100
    
    # Zamanlayıcı
    fetch_interval_minutes: int = 30
    cleanup_interval_hours: int = 6
    max_news_age_days: int = 30
    
    # Sinyal
    signal_threshold: float = 0.55
    positive_keywords: str = ""
    negative_keywords: str = ""
    
    # Güvenlik
    secret_key: str = ""
    cors_origins: str = ""
    
    # ---------- Hesaplanmış Özellikler ----------
    
    @property
    def parsed_rss_feeds(self) -> List[dict]:
        """RSS_FEEDS env'ini parse et: name|url|weight|enabled"""
        feeds = []
        for item in self.rss_feeds.split(","):
            item = item.strip()
            if not item:
                continue
            parts = item.split("|")
            if len(parts) >= 2:
                feeds.append({
                    "name": parts[0].strip(),
                    "url": parts[1].strip(),
                    "weight": float(parts[2]) if len(parts) > 2 else 0.8,
                    "enabled": parts[3].lower() == "true" if len(parts) > 3 else True,
                })
        return feeds
    
    @property
    def parsed_youtube_channels(self) -> List[str]:
        return [c.strip() for c in self.youtube_channels.split(",") if c.strip()]
    
    @property
    def parsed_positive_keywords(self) -> List[str]:
        return [k.strip().lower() for k in self.positive_keywords.split(",") if k.strip()]
    
    @property
    def parsed_negative_keywords(self) -> List[str]:
        return [k.strip().lower() for k in self.negative_keywords.split(",") if k.strip()]
    
    @property
    def parsed_cors_origins(self) -> List[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()