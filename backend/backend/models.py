# ==========================================
# BORSA SİNYAL BACKEND - VERİTABANI MODELLERİ
# ==========================================
from __future__ import annotations

import uuid
from datetime import datetime
from enum import Enum as PyEnum
from typing: Optional

from sqlalchemy import (
    JSON,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.sqlite import JSON as SQLiteJSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.database import Base


class SourceType(str, PyEnum):
    RSS = "rss"
    YOUTUBE = "youtube"
    KAP = "kap"
    CUSTOM = "custom"


class SignalDirection(str, PyEnum):
    UP = "UP"
    DOWN = "DOWN"
    FLAT = "FLAT"


class NewsSource(Base):
    __tablename__ = "news_sources"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    type: Mapped[SourceType] = mapped_column(String(20), nullable=False)
    url: Mapped[str] = mapped_column(String(500), nullable=False)
    enabled: Mapped[bool] = mapped_column(default=True, nullable=False)
    weight: Mapped[float] = mapped_column(Float, default=0.8, nullable=False)
    config: Mapped[dict] = mapped_column(SQLiteJSON, default=dict, nullable=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
    last_fetched_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    last_error: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    news_items: Mapped[list["NewsItem"]] = relationship("NewsItem", back_populates="source", lazy="dynamic")
    
    __table_args__ = (
        Index("ix_news_sources_enabled", "enabled"),
        Index("ix_news_sources_type", "type"),
    )


class NewsItem(Base):
    __tablename__ = "news_items"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    source_id: Mapped[str] = mapped_column(String(36), ForeignKey("news_sources.id", ondelete="CASCADE"), nullable=False, index=True)
    
    title: Mapped[str] = mapped_column(String(500), nullable=False)
    summary: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    content: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    url: Mapped[str] = mapped_column(String(500), nullable=False)
    author: Mapped[Optional[str]] = mapped_column(String(200), nullable=True)
    tags: Mapped[list[str]] = mapped_column(SQLiteJSON, default=list, nullable=False)
    
    published_at: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    fetched_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    processed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
    sentiment_score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    relevant_tickers: Mapped[list[str]] = mapped_column(SQLiteJSON, default=list, nullable=False)
    
    source: Mapped["NewsSource"] = relationship("NewsSource", back_populates="news_items")
    
    __table_args__ = (
        Index("ix_news_items_published_at", "published_at"),
        Index("ix_news_items_fetched_at", "fetched_at"),
        Index("ix_news_items_sentiment", "sentiment_score"),
        UniqueConstraint("source_id", "url", name="uq_news_source_url"),
    )


class Signal(Base):
    __tablename__ = "signals"
    
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    date: Mapped[datetime] = mapped_column(DateTime, nullable=False, unique=True, index=True)
    
    direction: Mapped[SignalDirection] = mapped_column(String(10), nullable=False)
    confidence: Mapped[float] = mapped_column(Float, nullable=False)
    
    components: Mapped[dict] = mapped_column(SQLiteJSON, default=dict, nullable=False)
    
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    
    __table_args__ = (
        Index("ix_signals_date", "date"),
        Index("ix_signals_direction", "direction"),
    )


class ModelMetrics(Base):
    __tablename__ = "model_metrics"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    
    accuracy: Mapped[float] = mapped_column(Float, nullable=False)
    precision: Mapped[float] = mapped_column(Float, nullable=False)
    recall: Mapped[float] = mapped_column(Float, nullable=False)
    f1_score: Mapped[float] = mapped_column(Float, nullable=False)
    confusion_matrix: Mapped[list[list[int]]] = mapped_column(SQLiteJSON, nullable=False)
    
    training_samples: Mapped[int] = mapped_column(Integer, nullable=False)
    feature_count: Mapped[int] = mapped_column(Integer, nullable=False)
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    
    last_trained_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)