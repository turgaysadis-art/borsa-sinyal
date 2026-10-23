# ==========================================
# BORSA SİNYAL BACKEND - ZAMANLAYICI
# ==========================================
from __future__ import annotations

import logging
from datetime import datetime, timezone, timedelta
from typing: Optional

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger

from backend.config import get_settings
from backend.database import get_session
from backend.fetchers import RSSFetcher, YouTubeFetcher, KAPFetcher
from backend.models import NewsItem, NewsSource, Signal, SourceType
from backend.nlp import SentimentAnalyzer, SignalModel, SimpleRuleBasedModel
from backend.fusion.engine import FusionEngine, FusionInput
from backend.technical.indicators import TechnicalAnalyzer

logger = logging.getLogger(__name__)


class SignalScheduler:
    """Periyodik veri çekme, işleme ve sinyal üretme."""
    
    def __init__(self):
        settings = get_settings()
        self.fetch_interval = settings.fetch_interval_minutes
        self.cleanup_interval = settings.cleanup_interval_hours
        self.max_news_age = settings.max_news_age_days
        self.signal_threshold = settings.signal_threshold
        
        self.rss_fetcher = RSSFetcher()
        self.youtube_fetcher = YouTubeFetcher()
        self.kap_fetcher = KAPFetcher()
        
        self.sentiment_analyzer = SentimentAnalyzer()
        self.ml_model = SignalModel()
        self.fallback_model = SimpleRuleBasedModel()
        self.fusion_engine = FusionEngine()
        self.technical_analyzer = TechnicalAnalyzer()
        
        self.scheduler = AsyncIOScheduler()
        self._running = False
    
    async def start(self):
        if self._running:
            return
        
        # Mevcut modeli yükle
        self.ml_model.load()
        
        # Job'ları ekle
        self.scheduler.add_job(
            self.fetch_all_sources,
            IntervalTrigger(minutes=self.fetch_interval),
            id="fetch_news",
            name="Haberleri çek ve işle",
            replace_existing=True,
        )
        
        self.scheduler.add_job(
            self.generate_daily_signal,
            IntervalTrigger(hours=1),
            id="generate_signal",
            name="Günlük sinyal üret",
            replace_existing=True,
        )
        
        self.scheduler.add_job(
            self.cleanup_old_news,
            IntervalTrigger(hours=self.cleanup_interval),
            id="cleanup",
            name="Eski haberleri temizle",
            replace_existing=True,
        )
        
        self.scheduler.start()
        self._running = True
        logger.info("Scheduler started")
        
        # İlk çalışmayı hemen yap
        await self.fetch_all_sources()
        await self.generate_daily_signal()
    
    async def stop(self):
        if not self._running:
            return
        
        self.scheduler.shutdown(wait=True)
        await self.rss_fetcher.close()
        await self.kap_fetcher.close()
        self._running = False
        logger.info("Scheduler stopped")
    
    async def fetch_all_sources(self):
        """Tüm kaynaklardan haber çek."""
        logger.info("Starting scheduled fetch...")
        
        async with get_session() as session:
            from sqlalchemy import select
            result = await session.execute(
                select(NewsSource).where(NewsSource.enabled == True)
            )
            sources = result.scalars().all()
            
            total_fetched = 0
            
            for source in sources:
                try:
                    items = await self._fetch_source(source)
                    if items:
                        saved = await self._save_news_items(session, items)
                        total_fetched += saved
                        logger.info(f"Saved {saved} new items from {source.name}")
                    
                    # Source güncelle
                    source.last_fetched_at = datetime.now(timezone.utc)
                    source.last_error = None
                    await session.commit()
                    
                except Exception as e:
                    logger.error(f"Error fetching {source.name}: {e}")
                    source.last_error = str(e)
                    await session.commit()
            
            logger.info(f"Fetch completed. Total new items: {total_fetched}")
    
    async def _fetch_source(self, source: NewsSource) -> list[NewsItem]:
        """Kaynak tipine göre fetcher seç ve çek."""
        if source.type == SourceType.RSS:
            return await self.rss_fetcher.fetch(source)
        elif source.type == SourceType.YOUTUBE:
            return await self.youtube_fetcher.fetch(source)
        elif source.type == SourceType.KAP:
            return await self.kap_fetcher.fetch(source)
        else:
            logger.warning(f"Unknown source type: {source.type}")
            return []
    
    async def _save_news_items(self, session, items: list[NewsItem]) -> int:
        """Haberleri veritabanına kaydet (duplicate kontrolü ile)."""
        from sqlalchemy import select
        
        saved = 0
        for item in items:
            # URL bazlı duplicate kontrol
            existing = await session.execute(
                select(NewsItem).where(
                    NewsItem.source_id == item.source_id,
                    NewsItem.url == item.url,
                )
            )
            if existing.scalar_one_or_none():
                continue
            
            # Kategori etiketle
            item.tags = self._categorize_news(item)
            
            # Sentiment analizi
            text = f"{item.title} {item.summary or ''} {item.content or ''}"
            sentiment = self.sentiment_analyzer.analyze(text)
            item.sentiment_score = sentiment
            
            session.add(item)
            saved += 1
        
        if saved > 0:
            await session.commit()
        
        return saved
    
    def _categorize_news(self, item: NewsItem) -> list[str]:
        """Haber kategorisi etiketle."""
        text = f"{item.title} {item.summary or ''} {item.content or ''}".lower()
        tags = []
        
        # Kategori keyword'leri
        categories = {
            "ekonomik": ["ekonomi", "enflasyon", "faiz", "büyüme", "gsyh", "işsizlik", "tüketici", "üretim", "ihracat", "ithalat", "cari açık", "bütçe", "borç", "döviz", "kuruş", "lira"],
            "politik_ic": ["cumhurbaşkanı", "başbakan", "bakan", "meclis", "seçim", "oy", "yasa", "kanun", "referandum", "anayasa", "parti", "milletvekili"],
            "geopolitik_savas": ["savaş", "çatışma", "mühimmat", "askeri", "hudut", "sınır", "operasyon", "havaalanı", "füz", "roket", "bombardıman", "iha", "sih", "rusya", "ukrayna", "ısrail", "filistin", "gazze", "lübnan", "suriye", "iran"],
            "kuresel_denge": ["fed", "merkez bankası", "ekb", "abo", "faiz kararı", "para politikası", "dolar endeksi", "petrol", "brent", "wti", "opec", "ticaret savaşı", "gümrük", "tarife", "yaptırım", "brics", "g20", "g7", "nato"],
            "uluslararasi": ["ab", "avrupa birliği", "almanya", "fransa", "abd", "çin", "japonya", "hint", "brezilya", "güney kore", "birleşmiş milletler", "bm", "dünya bankası", "imf"],
            "sektor_ozel": ["banka", "holding", "teknoloji", "enerji", "otomotiv", "madencilik", "perakende", "ilaç", "telekom", "gıda", "içecek", "sigorta", "cam", "havacılık", "petrokimya", "demir çelik", "altın"],
            "sirket_ozel": ["kâr", "zarar", "gelir", "satış", "bölme", "birleşme", "devralma", "yatırım", "fabrika", "kapasite", "üretim", "satışları", "müşteri", "sözleşme", "ihale"],
            "kap_bildirim": ["kap", "kamuoyu aydınlatma", "bildirim", "özgürlük", "malı durum"],
        }
        
        for cat, keywords in categories.items():
            if any(kw in text for kw in keywords):
                tags.append(cat)
        
        # Ticker çıkar (BIST hisse kodları)
        import re
        ticker_pattern = r'\b[A-Z]{3,5}\b'
        tickers = re.findall(ticker_pattern, text.upper())
        # Bilinen BIST hisse kodlarıyla filtrele
        known_tickers = {
            "THYAO", "GARAN", "AKBNK", "ISCTR", "YKBNK", "VAKBN", "HALKB", "TSKB",
            "SAHOL", "KCHOL", "DOAS", "ASELS", "HEKTS", "TUPRS", "PETKM", "AEGAZ",
            "EREGL", "KRDMD", "KOZAL", "KOZAA", "BIMAS", "MGROS", "SOKM",
            "TOASO", "FROTO", "OTKAR", "MPARK", "GENTS", "TTKOM", "TRKCM",
            "SISE", "PGSUS", "ULKER", "CCOLA", "ANHYT", "XU100", "XU030", "XU050",
            "XBANK", "XHOLD", "XTECH", "XELKT", "XFINK", "XGIDA", "XULAS", "XMESY", "XSINE"
        }
        relevant = [t for t in tickers if t in known_tickers]
        item.relevant_tickers = list(set(relevant))
        
        return tags
    
    async def generate_daily_signal(self):
        """Günlük sinyal üret (Fusion Engine kullan)."""
        logger.info("Generating daily signal with Fusion Engine...")
        
        async with get_session() as session:
            from sqlalchemy import select, func
            
            # Bugünün tarihi
            today = datetime.now(timezone.utc).date()
            
            # Bugün zaten sinyal var mı?
            existing = await session.execute(
                select(Signal).where(func.date(Signal.date) == today)
            )
            if existing.scalar_one_or_none():
                logger.info("Signal already exists for today")
                return
            
            # Son 24 saatin haberlerini getir
            since = datetime.now(timezone.utc) - timedelta(hours=24)
            
            result = await session.execute(
                select(NewsItem)
                .where(NewsItem.fetched_at >= since)
                .where(NewsItem.sentiment_score.is_not(None))
            )
            news_items = result.scalars().all()
            
            if len(news_items) < 5:
                logger.warning(f"Not enough news for signal: {len(news_items)}")
                return
            
            # Teknik analizleri çek
            technical_snapshots = self.technical_analyzer.fetch_all()
            
            # Fusion Input hazırla
            fusion_input = self._prepare_fusion_input(news_items, technical_snapshots)
            
            # Fusion Engine ile analiz et
            fusion_output = self.fusion_engine.analyze(fusion_input)
            
            # Sinyal oluştur
            signal = Signal(
                date=datetime.combine(today, datetime.min.time()).replace(tzinfo=timezone.utc),
                direction=fusion_output.direction,
                confidence=fusion_output.confidence,
                components={
                    "news_count": len(news_items),
                    "weighted_sentiment": fusion_input.news_sentiment,
                    "threshold": self.signal_threshold,
                    "fusion_components": fusion_output.component_scores,
                    "fusion_weights": fusion_output.weights_used,
                    "explanation": fusion_output.explanation,
                    "key_drivers": fusion_output.key_drivers,
                    "risk_factors": fusion_output.risk_factors,
                    "source_breakdown": fusion_input.source_breakdown,
                },
                model_version=self.ml_model.model_version,
            )
            
            session.add(signal)
            await session.commit()
            
            logger.info(f"Daily signal generated: {fusion_output.direction.value} ({fusion_output.confidence:.2f})")
    
    def _prepare_fusion_input(self, news_items: list[NewsItem], technical_snapshots: dict) -> FusionInput:
        """Fusion Engine girişi hazırla."""
        # Haber sentiment analizi
        total_weight = 0
        weighted_sentiment = 0
        source_breakdown = {}
        
        positive_keywords = []
        negative_keywords = []
        
        for item in news_items:
            # Source weight
            source_weight = 0.8  # default
            # Source'dan weight almaya çalış
            
            if item.sentiment_score is not None:
                weighted_sentiment += item.sentiment_score * source_weight
                total_weight += source_weight
            
            # Source breakdown
            sname = "unknown"
            if sname not in source_breakdown:
                source_breakdown[sname] = {"count": 0, "sentiment_sum": 0, "weight": source_weight}
            source_breakdown[sname]["count"] += 1
            source_breakdown[sname]["sentiment_sum"] += item.sentiment_score or 0
            
            # Keywords topla
            detail = self.sentiment_analyzer.analyze_detailed(f"{item.title} {item.summary or ''}")
            positive_keywords.extend(detail["positive"])
            negative_keywords.extend(detail["negative"])
        
        avg_sentiment = weighted_sentiment / total_weight if total_weight > 0 else 0
        
        # En yaygın keyword'ler
        from collections import Counter
        pos_counter = Counter(positive_keywords)
        neg_counter = Counter(negative_keywords)
        top_pos = [k for k, _ in pos_counter.most_common(10)]
        top_neg = [k for k, _ in neg_counter.most_common(10)]
        
        # BIST100 ve USDTRY skorları
        bist100 = technical_snapshots.get("XU100.IS")
        usdtry = technical_snapshots.get("USDTRY=X")
        
        bist100_score = bist100.technical_score if bist100 else 0
        usdtry_score = -usdtry.technical_score if usdtry else 0  # Ters korelasyon
        
        # Piyasa rejimi belirle (basit)
        market_regime = "NEUTRAL"
        if bist100 and bist100.trend_long == "UP" and bist100.dist_ema200_pct > 0:
            market_regime = "BULL"
        elif bist100 and bist100.trend_long == "DOWN" and bist100.dist_ema200_pct < -5:
            market_regime = "BEAR"
        elif bist100 and bist100.rsi_14 > 70:
            market_regime = "VOLATILE"
        
        # KAP sentiment (KAP kaynaklı haberlerden)
        kap_items = [n for n in news_items if "kap_bildirim" in n.tags]
        kap_sentiment = 0
        if kap_items:
            kap_sentiment = sum(n.sentiment_score or 0 for n in kap_items) / len(kap_items)
        
        return FusionInput(
            news_sentiment=avg_sentiment,
            news_count=len(news_items),
            news_confidence=min(len(news_items) / 50, 1.0),
            top_positive_keywords=top_pos,
            top_negative_keywords=top_neg,
            source_breakdown=source_breakdown,
            kap_sentiment=kap_sentiment,
            kap_event_count=len(kap_items),
            kap_weight=0.15,
            technical_snapshots=technical_snapshots,
            bist100_score=bist100_score,
            usdtry_score=usdtry_score,
            market_regime=market_regime,
            audio_sentiment=0.0,  # Şimdilik 0, ileride audio analyzer eklenecek
            audio_count=0,
            global_risk="NEUTRAL",
        )
    
    async def cleanup_old_news(self):
        """Eski haberleri temizle."""
        from sqlalchemy import delete
        
        cutoff = datetime.now(timezone.utc) - timedelta(days=self.max_news_age)
        
        async with get_session() as session:
            result = await session.execute(
                delete(NewsItem).where(NewsItem.fetched_at < cutoff)
            )
            await session.commit()
            logger.info(f"Cleaned up {result.rowcount} old news items")
    
    async def manual_fetch(self) -> dict:
        """Manuel tetikleme için."""
        await self.fetch_all_sources()
        await self.generate_daily_signal()
        return {"status": "completed"}
    
    async def retrain_model(self) -> dict:
        """Modeli yeniden eğit (geçmiş verilerle)."""
        # Bu kısım için etiketlenmiş veri gerekir
        return {"status": "not_implemented", "message": "Labelled data required"}