# ==========================================
# BORSA SİNYAL BACKEND - FÜZYON MOTORU
# ==========================================
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing: Optional, List
import numpy as np

from backend.nlp.model import SignalModel, SimpleRuleBasedModel
from backend.technical.indicators import TechnicalAnalyzer, TechnicalSnapshot
from backend.models import SignalDirection
from backend.config import get_settings

@dataclass
class FusionInput:
    # Haber sentiment
    news_sentiment: float = 0.0
    news_count: int = 0
    news_confidence: float = 0.0
    top_positive_keywords: List[str] = field(default_factory=list)
    top_negative_keywords: List[str] = field(default_factory=list)
    source_breakdown: dict = field(default_factory=dict)
    
    # KAP / Özel olay
    kap_sentiment: float = 0.0
    kap_event_count: int = 0
    kap_weight: float = 0.15
    
    # Teknik analiz
    technical_snapshots: dict[str, TechnicalSnapshot] = field(default_factory=dict)
    bist100_score: float = 0.0
    usdtry_score: float = 0.0
    market_regime: str = "NEUTRAL"
    
    # Ses/Video
    audio_sentiment: float = 0.0
    audio_count: int = 0
    
    # Piyasa rejimi (makro)
    vix_level: Optional[float] = None
    global_risk: str = "NEUTRAL"


@dataclass
class FusionOutput:
    direction: SignalDirection
    confidence: float
    component_scores: dict[str, float]
    weights_used: dict[str, float]
    explanation: str
    key_drivers: List[str]
    risk_factors: List[str]


class FusionEngine:
    """Tüm sinyalleri birleştirip final karar veren motor."""
    
    DEFAULT_WEIGHTS = {
        "news": 0.30,
        "kap": 0.15,
        "technical": 0.35,
        "audio": 0.10,
        "macro": 0.10,
    }
    
    def __init__(self):
        settings = get_settings()
        self.weights = self.DEFAULT_WEIGHTS.copy()
        self.signal_threshold = settings.signal_threshold
        self.ml_model = SignalModel()
        self.fallback_model = SimpleRuleBasedModel()
        self.technical_analyzer = TechnicalAnalyzer()
    
    def analyze(self, fusion_input: FusionInput) -> FusionOutput:
        """Ana analiz fonksiyonu."""
        
        # 1. Bileşen skorları
        components = {}
        
        # Haber sentiment (ağırlıklı kaynak bazlı)
        components["news"] = fusion_input.news_sentiment * fusion_input.news_confidence
        
        # KAP
        components["kap"] = fusion_input.kap_sentiment * min(fusion_input.kap_event_count / 10, 1.0)
        
        # Teknik (BIST100 + USDTRY + diğerleri)
        components["technical"] = self._calculate_technical_component(fusion_input)
        
        # Ses
        components["audio"] = fusion_input.audio_sentiment * min(fusion_input.audio_count / 5, 1.0)
        
        # Makro
        components["macro"] = self._calculate_macro_component(fusion_input)
        
        # 2. Ağırlıklı toplam
        weighted_sum = sum(
            components[k] * self.weights.get(k, 0) 
            for k in components
        )
        
        # 3. ML modeli varsa meta-öğrenme ile düzelt
        ml_adjustment = 0.0
        if self.ml_model.is_trained:
            ml_adjustment = self._get_ml_adjustment(fusion_input, weighted_sum)
            weighted_sum = 0.7 * weighted_sum + 0.3 * ml_adjustment
        
        # 4. Yön belirle
        if weighted_sum > self.signal_threshold:
            direction = SignalDirection.UP
        elif weighted_sum < -self.signal_threshold:
            direction = SignalDirection.DOWN
        else:
            direction = SignalDirection.FLAT
        
        # 5. Güven hesapla
        confidence = self._calculate_confidence(weighted_sum, components, fusion_input)
        
        # 6. Açıklama üret
        explanation, key_drivers, risk_factors = self._generate_explanation(
            direction, weighted_sum, components, fusion_input
        )
        
        return FusionOutput(
            direction=direction,
            confidence=confidence,
            component_scores=components,
            weights_used=self.weights.copy(),
            explanation=explanation,
            key_drivers=key_drivers,
            risk_factors=risk_factors,
        )
    
    def _calculate_technical_component(self, inp: FusionInput) -> float:
        """Teknik analiz bileşen skoru."""
        scores = []
        
        # BIST100 en önemli
        bist = inp.technical_snapshots.get("XU100.IS")
        if bist:
            scores.append(("BIST100", bist.technical_score, 0.5))
        
        # USDTRY (ters korelasyon genelde)
        usdtry = inp.technical_snapshots.get("USDTRY=X")
        if usdtry:
            scores.append(("USDTRY", -usdtry.technical_score, 0.2))
        
        # Diğer endeksler
        for sym in ["XU030.IS", "XBANK.IS", "XHOLD.IS"]:
            snap = inp.technical_snapshots.get(sym)
            if snap:
                scores.append((sym, snap.technical_score, 0.1))
        
        # Altın/Petrol
        for sym in ["GC=F", "CL=F"]:
            snap = inp.technical_snapshots.get(sym)
            if snap:
                scores.append((sym, snap.technical_score * 0.5, 0.05))
        
        if not scores:
            return 0.0
        
        total_weight = sum(w for _, _, w in scores)
        weighted = sum(s * w for _, s, w in scores) / total_weight if total_weight > 0 else 0
        
        return max(-1.0, min(1.0, weighted))
    
    def _calculate_macro_component(self, inp: FusionInput) -> float:
        score = 0.0
        
        # Global risk algısı
        if inp.global_risk == "RISK_ON":
            score += 0.3
        elif inp.global_risk == "RISK_OFF":
            score -= 0.3
        
        # VIX seviyesi
        if inp.vix_level:
            if inp.vix_level < 15:
                score += 0.2
            elif inp.vix_level > 30:
                score -= 0.2
        
        # Piyasa rejimi
        regime_scores = {
            "BULL": 0.3,
            "BEAR": -0.3,
            "NEUTRAL": 0.0,
            "VOLATILE": -0.1,
        }
        score += regime_scores.get(inp.market_regime, 0)
        
        return max(-1.0, min(1.0, score))
    
    def _get_ml_adjustment(self, inp: FusionInput, base_score: float) -> float:
        """ML modeli ile düzeltme."""
        try:
            # Özellik vektörü hazırla
            features = [
                inp.news_sentiment,
                inp.news_count / 100,
                inp.kap_sentiment,
                inp.bist100_score,
                inp.usdtry_score,
                inp.audio_sentiment,
                1.0 if inp.global_risk == "RISK_ON" else -1.0 if inp.global_risk == "RISK_OFF" else 0.0,
                1.0 if inp.market_regime == "BULL" else -1.0 if inp.market_regime == "BEAR" else 0.0,
            ]
            
            # Basit: ML modeli doğrudan direction tahmin ediyor, skor değil
            # Burada base_score'a yakın bir düzeltme döndürüyoruz
            return base_score  # Placeholder
            
        except Exception:
            return base_score
    
    def _calculate_confidence(self, weighted_sum: float, components: dict, inp: FusionInput) -> float:
        """Güven skoru (0-1)."""
        # Mutlak skor büyüklüğü
        base_conf = min(abs(weighted_sum) * 1.5, 0.85)
        
        # Veri kalitesi bonusları
        quality_bonus = 0.0
        if inp.news_count >= 20:
            quality_bonus += 0.05
        if inp.kap_event_count >= 5:
            quality_bonus += 0.03
        if inp.audio_count >= 3:
            quality_bonus += 0.02
        if len(inp.technical_snapshots) >= 5:
            quality_bonus += 0.05
        
        # Bileşenler tutarlı mı?
        signs = [np.sign(v) for v in components.values() if v != 0]
        if signs:
            consistency = sum(1 for s in signs if s == np.sign(weighted_sum)) / len(signs)
            quality_bonus += (consistency - 0.5) * 0.1
        
        return max(0.45, min(0.95, base_conf + quality_bonus))
    
    def _generate_explanation(self, direction: SignalDirection, score: float,
                              components: dict, inp: FusionInput) -> tuple[str, List[str], List[str]]:
        """İnsan okunabilir açıklama."""
        
        dir_tr = {"UP": "YÜKSELİŞ", "DOWN": "DÜŞÜŞ", "FLAT": "YATAY"}
        dir_label = dir_tr[direction.value]
        
        # Ana sürücüler
        drivers = []
        risks = []
        
        # Haber
        if abs(components.get("news", 0)) > 0.15:
            if components["news"] > 0:
                drivers.append(f"Haber sentiment pozitif ({components['news']:.2f})")
                if inp.top_positive_keywords:
                    drivers.append(f"Anahtar kelimeler: {', '.join(inp.top_positive_keywords[:3])}")
            else:
                risks.append(f"Haber sentiment negatif ({components['news']:.2f})")
                if inp.top_negative_keywords:
                    risks.append(f"Risk kelimeler: {', '.join(inp.top_negative_keywords[:3])}")
        
        # Teknik
        tech = components.get("technical", 0)
        if abs(tech) > 0.15:
            bist = inp.technical_snapshots.get("XU100.IS")
            if bist:
                if tech > 0:
                    drivers.append(f"Teknik yapı olumlu: EMA200 %{bist.dist_ema200_pct:+.1f}, Trend: {bist.trend_long}")
                else:
                    risks.append(f"Teknik yapı olumsuz: EMA200 %{bist.dist_ema200_pct:+.1f}, Trend: {bist.trend_long}")
                if bist.rsi_14 > 70:
                    risks.append(f"RSI aşırı alım bölgesinde ({bist.rsi_14:.0f})")
                elif bist.rsi_14 < 30:
                    drivers.append(f"RSI aşırı satım bölgesinde ({bist.rsi_14:.0f})")
        
        # KAP
        if inp.kap_event_count > 0:
            if components.get("kap", 0) > 0:
                drivers.append(f"KAP bildirimleri olumlu ({inp.kap_event_count} adet)")
            else:
                risks.append(f"KAP bildirimleri olumsuz ({inp.kap_event_count} adet)")
        
        # Makro
        macro = components.get("macro", 0)
        if macro > 0.1:
            drivers.append(f"Global risk algısı: {inp.global_risk}, Piyasa rejimi: {inp.market_regime}")
        elif macro < -0.1:
            risks.append(f"Global risk algısı: {inp.global_risk}, Piyasa rejimi: {inp.market_regime}")
        
        # Ses
        if inp.audio_count > 0:
            if components.get("audio", 0) > 0.1:
                drivers.append(f"Video/analiz içerikleri olumlu ({inp.audio_count} video)")
            elif components.get("audio", 0) < -0.1:
                risks.append(f"Video/analiz içerikleri olumsuz ({inp.audio_count} video)")
        
        # Özet cümle
        explanation = (
            f"Günlük sinyal: {dir_label} (skor: {score:+.2f}, güven: %{int(confidence*100)}). "
            f"Haber: {components.get('news',0):+.2f}, Teknik: {tech:+.2f}, KAP: {components.get('kap',0):+.2f}, "
            f"Ses: {components.get('audio',0):+.2f}, Makro: {macro:+.2f}."
        )
        
        return explanation, drivers[:5], risks[:5]