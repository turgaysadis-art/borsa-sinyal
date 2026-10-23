# ==========================================
# BORSA SİNYAL BACKEND - TEKNİK ANALİZ
# ==========================================
from __future__ import annotations

import logging
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Optional, List
import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)

# yfinance optional import
try:
    import yfinance as yf
    YFINANCE_AVAILABLE = True
except ImportError:
    YFINANCE_AVAILABLE = False
    logger.warning("yfinance not installed. Technical analysis will use mock data.")


@dataclass
class TechnicalSnapshot:
    """Teknik analiz anlık görüntüsü."""
    symbol: str
    timestamp: datetime
    close: float
    
    # EMA
    ema_5: float
    ema_21: float
    ema_50: float
    ema_200: float
    
    # Trend durumu
    trend_short: str      # "UP" / "DOWN" / "FLAT"
    trend_medium: str
    trend_long: str
    
    # Mesafe yüzdeleri
    dist_ema5_pct: float
    dist_ema21_pct: float
    dist_ema50_pct: float
    dist_ema200_pct: float
    
    # Diğer göstergeler
    rsi_14: float
    macd: float
    macd_signal: float
    macd_histogram: float
    
    # Hacim
    volume: int
    volume_avg_20: int
    volume_ratio: float
    
    # Destek/Direnç
    resistance_20: float
    support_20: float
    
    # Skor ve özet
    technical_score: float
    summary: str
    
    # Market Overview için
    change: float = 0.0
    change_pct: float = 0.0
    sparkline_data: List[float] = field(default_factory=list)
    prev_close: float = 0.0


class TechnicalAnalyzer:
    """Teknik analiz motoru."""
    
    def __init__(self, symbols: Optional[List[str]] = None):
        self.symbols = symbols or [
            "XU100.IS",   # BIST100
            "XU030.IS",   # BIST30
            "XU050.IS",   # BIST50
            "XBANK.IS",   # BIST Banka
            "XHOLD.IS",   # BIST Holding
            "XTECH.IS",   # BIST Teknoloji
            "XELKT.IS",   # BIST Elektrik
            "XFINK.IS",   # BIST Finansal
            "XGIDA.IS",   # BIST Gıda
            "XULAS.IS",   # BIST Ulaştırma
            "XMESY.IS",   # BIST Metal
            "XSINE.IS",   # BIST Sınai
            "USDTRY=X",   # USD/TRY
            "EURTRY=X",   # EUR/TRY
            "GC=F",       # Altın
            "CL=F",       # Petrol (WTI)
            "BZ=F",       # Petrol (Brent)
            "SI=F",       # Gümüş
        ]
    
    def fetch_all(self) -> dict[str, TechnicalSnapshot]:
        """Tüm semboller için anlık teknik analiz."""
        results = {}
        for symbol in self.symbols:
            try:
                snapshot = self.analyze_symbol(symbol)
                results[symbol] = snapshot
            except Exception as e:
                logger.error(f"Technical analysis failed for {symbol}: {e}")
        return results
    
    def analyze_symbol(self, symbol: str, period: str = "1y") -> TechnicalSnapshot:
        """Tek sembol için detaylı teknik analiz."""
        if not YFINANCE_AVAILABLE:
            return self._mock_snapshot(symbol)
        
        try:
            ticker = yf.Ticker(symbol)
            hist = ticker.history(period=period, interval="1d")
            
            if len(hist) < 200:
                # Yeterli veri yoksa mevcut veriyle yap
                if len(hist) < 50:
                    raise ValueError(f"Yetersiz veri: {len(hist)} gün")
            
            close = hist['Close']
            volume = hist['Volume']
            
            # EMA hesapla
            ema_5 = close.ewm(span=5, adjust=False).mean().iloc[-1]
            ema_21 = close.ewm(span=21, adjust=False).mean().iloc[-1]
            ema_50 = close.ewm(span=50, adjust=False).mean().iloc[-1]
            ema_200 = close.ewm(span=200, adjust=False).mean().iloc[-1]
            
            current_price = close.iloc[-1]
            
            # Trendler
            trend_short = self._get_trend(ema_5, ema_21)
            trend_medium = self._get_trend(ema_21, ema_50)
            trend_long = self._get_trend(ema_50, ema_200)
            
            # Mesafe yüzdeleri
            dist_ema5_pct = (current_price - ema_5) / ema_5 * 100
            dist_ema21_pct = (current_price - ema_21) / ema_21 * 100
            dist_ema50_pct = (current_price - ema_50) / ema_50 * 100
            dist_ema200_pct = (current_price - ema_200) / ema_200 * 100
            
            # RSI
            rsi_14 = self._calculate_rsi(close, 14).iloc[-1]
            
            # MACD
            macd_line = close.ewm(span=12).mean() - close.ewm(span=26).mean()
            macd_signal = macd_line.ewm(span=9).mean()
            macd_histogram = macd_line - macd_signal
            macd = macd_line.iloc[-1]
            macd_sig = macd_signal.iloc[-1]
            macd_hist = macd_histogram.iloc[-1]
            
            # Hacim
            vol_avg_20 = volume.rolling(20).mean().iloc[-1]
            vol_ratio = volume.iloc[-1] / vol_avg_20 if vol_avg_20 > 0 else 1
            
            # Destek/Direnç (son 20 gün)
            resistance_20 = hist['High'].rolling(20).max().iloc[-1]
            support_20 = hist['Low'].rolling(20).min().iloc[-1]
            
            # Teknik Skor Hesapla (-1, +1)
            score = self._calculate_technical_score(
                trend_short, trend_medium, trend_long,
                dist_ema200_pct, rsi_14, macd_hist, vol_ratio
            )
            
            # Günlük değişim
            prev_close = close.iloc[-2] if len(close) > 1 else current_price
            change = current_price - prev_close
            change_pct = (change / prev_close * 100) if prev_close != 0 else 0
            
            # Sparkline verisi (son 30 gün, normalize)
            recent_closes = hist['Close'].tail(30).tolist()
            if len(recent_closes) >= 2:
                min_c, max_c = min(recent_closes), max(recent_closes)
                range_c = max_c - min_c
                sparkline = [(c - min_c) / range_c if range_c > 0 else 0.5 for c in recent_closes]
            else:
                sparkline = [0.5]
            
            # Özet metin
            summary = self._generate_summary(
                symbol, current_price, trend_short, trend_medium, trend_long,
                dist_ema200_pct, rsi_14, macd_hist
            )
            
            return TechnicalSnapshot(
                symbol=symbol,
                timestamp=hist.index[-1].to_pydatetime() if hasattr(hist.index[-1], 'to_pydatetime') else datetime.now(timezone.utc),
                close=current_price,
                ema_5=ema_5, ema_21=ema_21, ema_50=ema_50, ema_200=ema_200,
                trend_short=trend_short, trend_medium=trend_medium, trend_long=trend_long,
                dist_ema5_pct=dist_ema5_pct, dist_ema21_pct=dist_ema21_pct,
                dist_ema50_pct=dist_ema50_pct, dist_ema200_pct=dist_ema200_pct,
                rsi_14=rsi_14, macd=macd, macd_signal=macd_sig, macd_histogram=macd_hist,
                volume=int(volume.iloc[-1]), volume_avg_20=int(vol_avg_20), volume_ratio=vol_ratio,
                resistance_20=resistance_20, support_20=support_20,
                technical_score=score, summary=summary,
                change=change, change_pct=change_pct, sparkline_data=sparkline, prev_close=prev_close,
            )
            
        except Exception as e:
            logger.error(f"Error analyzing {symbol}: {e}")
            return self._mock_snapshot(symbol)
    
    def _get_trend(self, fast: float, slow: float) -> str:
        if fast > slow * 1.001:  # %0.1 tolerans
            return "UP"
        elif fast < slow * 0.999:
            return "DOWN"
        return "FLAT"
    
    def _calculate_rsi(self, series: pd.Series, period: int) -> pd.Series:
        delta = series.diff()
        gain = delta.where(delta > 0, 0).rolling(period).mean()
        loss = -delta.where(delta < 0, 0).rolling(period).mean()
        rs = gain / loss.replace(0, np.nan)
        return 100 - (100 / (1 + rs))
    
    def _calculate_technical_score(self, trend_s, trend_m, trend_l,
                                   dist_ema200, rsi, macd_hist, vol_ratio) -> float:
        """Ağırlıklı teknik skor (-1 ile +1 arası)."""
        score = 0.0
        
        # Trend ağırlıkları
        trend_map = {"UP": 1, "FLAT": 0, "DOWN": -1}
        score += 0.35 * trend_map[trend_l]      # Uzun vadeli trend en önemli
        score += 0.25 * trend_map[trend_m]      # Orta vadeli
        score += 0.15 * trend_map[trend_s]      # Kısa vadeli
        
        # EMA200 mesafesi
        if dist_ema200 > 5:
            score += 0.15
        elif dist_ema200 > 0:
            score += 0.08
        elif dist_ema200 > -5:
            score -= 0.08
        else:
            score -= 0.15
        
        # RSI
        if rsi > 70:
            score -= 0.1  # Aşırı alım
        elif rsi < 30:
            score += 0.1  # Aşırı satım
        elif 40 <= rsi <= 60:
            score += 0.05  # Nötr bölge sağlıklı
        
        # MACD histogram
        if macd_hist > 0:
            score += 0.05
        else:
            score -= 0.05
        
        # Hacim onayı
        if vol_ratio > 1.5:
            score += 0.05
        
        return max(-1.0, min(1.0, score))
    
    def _generate_summary(self, symbol, price, ts, tm, tl, dist200, rsi, macd_hist) -> str:
        parts = []
        clean_sym = symbol.replace(".IS", "").replace("=X", "").replace("=F", "")
        
        parts.append(f"{clean_sym}: {price:.2f}")
        parts.append(f"Trend: K:{ts} O:{tm} U:{tl}")
        parts.append(f"EMA200: %{dist200:+.1f}")
        parts.append(f"RSI: {rsi:.0f}")
        parts.append(f"MACD: {'+' if macd_hist > 0 else '-'}")
        
        return " | ".join(parts)
    
    def _mock_snapshot(self, symbol: str) -> TechnicalSnapshot:
        """yfinance yoksa mock veri döndür."""
        import random
        base_price = 100.0
        if "XU100" in symbol: base_price = 10000
        elif "XU030" in symbol: base_price = 9500
        elif "XAGTRY" in symbol: base_price = 950
        elif "XAUTRY" in symbol: base_price = 2100
        elif "CL=F" in symbol: base_price = 80
        
        trend = random.choice(["UP", "DOWN", "FLAT"])
        score = random.uniform(-0.5, 0.5)
        
        return TechnicalSnapshot(
            symbol=symbol,
            timestamp=datetime.now(timezone.utc),
            close=base_price * random.uniform(0.98, 1.02),
            ema_5=base_price * 0.99, ema_21=base_price * 0.98, ema_50=base_price * 0.97, ema_200=base_price * 0.95,
            trend_short=trend, trend_medium=trend, trend_long=trend,
            dist_ema5_pct=random.uniform(-2, 2), dist_ema21_pct=random.uniform(-3, 3),
            dist_ema50_pct=random.uniform(-5, 5), dist_ema200_pct=random.uniform(-10, 10),
            rsi_14=random.uniform(30, 70), macd=random.uniform(-1, 1), macd_signal=0, macd_histogram=random.uniform(-0.5, 0.5),
            volume=1000000, volume_avg_20=1000000, volume_ratio=1.0,
            resistance_20=base_price * 1.05, support_20=base_price * 0.95,
            technical_score=score, summary=f"{symbol} (mock data)",
            change=base_price * random.uniform(-0.02, 0.02), change_pct=random.uniform(-2, 2),
            sparkline_data=[0.5 + random.uniform(-0.2, 0.2) for _ in range(30)],
            prev_close=base_price,
        )