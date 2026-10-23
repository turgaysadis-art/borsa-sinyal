# ==========================================
# BORSA SİNYAL BACKEND - SENTIMENT ANALIZI
# ==========================================
from __future__ import annotations

import logging
from typing: List

from backend.config import get_settings
from backend.nlp.text_processor import get_processor

logger = logging.getLogger(__name__)


class SentimentAnalyzer:
    """Kelime listesi tabanlı basit sentiment analizi + TF-IDF ağırlıklı."""
    
    def __init__(self):
        settings = get_settings()
        self.positive_words = set(settings.parsed_positive_keywords)
        self.negative_words = set(settings.parsed_negative_keywords)
        self.processor = get_processor()
        
        logger.info(f"Sentiment Analyzer initialized: {len(self.positive_words)} positive, {len(self.negative_words)} negative keywords")
    
    def analyze(self, text: str) -> float:
        """
        Metnin sentiment skorunu hesapla (-1 ile 1 arası).
        Pozitif = 1, Negatif = -1, Nötr = 0
        """
        if not text:
            return 0.0
        
        processed = self.processor.process(text)
        tokens = processed.split()
        
        if not tokens:
            return 0.0
        
        positive_count = sum(1 for t in tokens if t in self.positive_words)
        negative_count = sum(1 for t in tokens if t in self.negative_words)
        total_sentiment_tokens = positive_count + negative_count
        
        if total_sentiment_tokens == 0:
            return 0.0
        
        # Normalize edilmiş skor
        score = (positive_count - negative_count) / len(tokens)
        # -1 ile 1 arasına clamp et
        return max(-1.0, min(1.0, score * 10))  # Ölçeklendirme faktörü
    
    def analyze_detailed(self, text: str) -> dict:
        """Detaylı sentiment analizi."""
        if not text:
            return {"score": 0.0, "positive": [], "negative": [], "positive_count": 0, "negative_count": 0}
        
        processed = self.processor.process(text)
        tokens = processed.split()
        
        positive_found = [t for t in tokens if t in self.positive_words]
        negative_found = [t for t in tokens if t in self.negative_words]
        
        positive_count = len(positive_found)
        negative_count = len(negative_found)
        total_sentiment_tokens = positive_count + negative_count
        
        if total_sentiment_tokens == 0:
            score = 0.0
        else:
            score = (positive_count - negative_count) / len(tokens)
            score = max(-1.0, min(1.0, score * 10))
        
        return {
            "score": score,
            "positive": positive_found,
            "negative": negative_found,
            "positive_count": positive_count,
            "negative_count": negative_count,
        }
    
    def batch_analyze(self, texts: List[str]) -> List[float]:
        return [self.analyze(text) for text in texts]
    
    def get_keyword_stats(self) -> dict:
        """Kelime listesi istatistikleri."""
        return {
            "positive_count": len(self.positive_words),
            "negative_count": len(self.negative_words),
            "positive_words": sorted(list(self.positive_words))[:50],
            "negative_words": sorted(list(self.negative_words))[:50],
        }