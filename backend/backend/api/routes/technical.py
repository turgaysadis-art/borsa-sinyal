# ==========================================
# BORSA SİNYAL BACKEND - TECHNICAL ROUTES
# ==========================================
from __future__ import annotations

from fastapi import APIRouter, Query, HTTPException
from typing import Optional, List

from backend.technical.indicators import TechnicalAnalyzer

router = APIRouter()

# Global analyzer instance (cached)
_analyzer: TechnicalAnalyzer | None = None


def get_analyzer() -> TechnicalAnalyzer:
    global _analyzer
    if _analyzer is None:
        _analyzer = TechnicalAnalyzer()
    return _analyzer


def snapshot_to_dict(snap, include_full: bool = False) -> dict:
    """TechnicalSnapshot'ı dict'e çevir."""
    base = {
        "symbol": snap.symbol,
        "close": round(snap.close, 2),
        "change": round(snap.change, 2),
        "change_pct": round(snap.change_pct, 2),
        "sparkline_data": snap.sparkline_data,
        "ema_5": round(snap.ema_5, 2),
        "ema_21": round(snap.ema_21, 2),
        "ema_50": round(snap.ema_50, 2),
        "ema_200": round(snap.ema_200, 2),
        "dist_ema5_pct": round(snap.dist_ema5_pct, 2),
        "dist_ema21_pct": round(snap.dist_ema21_pct, 2),
        "dist_ema50_pct": round(snap.dist_ema50_pct, 2),
        "dist_ema200_pct": round(snap.dist_ema200_pct, 2),
        "trend_short": snap.trend_short,
        "trend_medium": snap.trend_medium,
        "trend_long": snap.trend_long,
        "rsi_14": round(snap.rsi_14, 1),
        "macd": round(snap.macd, 4),
        "macd_signal": round(snap.macd_signal, 4),
        "macd_histogram": round(snap.macd_histogram, 4),
        "volume": snap.volume,
        "volume_avg_20": snap.volume_avg_20,
        "volume_ratio": round(snap.volume_ratio, 2),
        "resistance_20": round(snap.resistance_20, 2),
        "support_20": round(snap.support_20, 2),
        "technical_score": round(snap.technical_score, 3),
        "summary": snap.summary,
        "timestamp": snap.timestamp.isoformat() if snap.timestamp else None,
    }
    
    if not include_full:
        # Market overview için minimal
        return {
            "symbol": snap.symbol,
            "close": base["close"],
            "change": base["change"],
            "change_pct": base["change_pct"],
            "sparkline_data": base["sparkline_data"],
            "ema_200": base["ema_200"],
            "dist_ema200_pct": base["dist_ema200_pct"],
            "rsi_14": base["rsi_14"],
            "trend_long": base["trend_long"],
            "trend_medium": base["trend_medium"],
            "trend_short": base["trend_short"],
            "volume_ratio": base["volume_ratio"],
            "summary": base["summary"],
            "timestamp": base["timestamp"],
        }
    
    return base


@router.get("/snapshots")
async def get_all_snapshots(
    symbols: Optional[str] = Query(None, description="Virgülle ayrılmış semboller"),
):
    """Tüm veya seçili semboller için teknik anlık görüntü."""
    analyzer = get_analyzer()
    
    if symbols:
        sym_list = [s.strip().upper() for s in symbols.split(",")]
        temp_analyzer = TechnicalAnalyzer(symbols=sym_list)
        data = temp_analyzer.fetch_all()
    else:
        data = analyzer.fetch_all()
    
    return {sym: snapshot_to_dict(snap) for sym, snap in data.items()}


@router.get("/market-overview")
async def get_market_overview():
    """Market Overview barı için optimize edilmiş veri (BIST30, Gümüş, Altın, Petrol)."""
    symbols = ["XU030.IS", "XAGTRY", "XAUTRY", "CL=F"]
    temp_analyzer = TechnicalAnalyzer(symbols=symbols)
    data = temp_analyzer.fetch_all()
    
    return {sym: snapshot_to_dict(snap) for sym, snap in data.items()}


@router.get("/snapshot/{symbol}")
async def get_snapshot(symbol: str):
    """Tek sembol için detaylı teknik analiz."""
    analyzer = get_analyzer()
    try:
        snap = analyzer.analyze_symbol(symbol.upper())
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Sembol analiz edilemedi: {str(e)}")
    
    return snapshot_to_dict(snap, include_full=True)


@router.get("/signals")
async def get_technical_signals(
    symbols: Optional[str] = Query(None, description="Virgülle ayrılmış semboller"),
):
    """Teknik analiz bazlı sinyaller (UP/DOWN/FLAT)."""
    analyzer = get_analyzer()
    
    if symbols:
        sym_list = [s.strip().upper() for s in symbols.split(",")]
        temp_analyzer = TechnicalAnalyzer(symbols=sym_list)
        data = temp_analyzer.fetch_all()
    else:
        data = analyzer.fetch_all()
    
    signals = {}
    for sym, snap in data.items():
        # Teknik skora göre sinyal
        score = snap.technical_score
        if score > 0.2:
            direction = "UP"
        elif score < -0.2:
            direction = "DOWN"
        else:
            direction = "FLAT"
        
        confidence = min(abs(score) * 1.5 + 0.3, 0.9)
        
        signals[sym] = {
            "symbol": sym,
            "direction": direction,
            "confidence": round(confidence, 2),
            "score": round(score, 3),
            "trend_long": snap.trend_long,
            "trend_medium": snap.trend_medium,
            "rsi_14": round(snap.rsi_14, 1),
            "dist_ema200_pct": round(snap.dist_ema200_pct, 2),
            "summary": snap.summary,
        }
    
    return signals


@router.get("/sector-performance")
async def get_sector_performance():
    """Sektör performansları (BIST hisseleri üzerinden)."""
    from backend.technical.indicators import TechnicalAnalyzer
    
    # BIST hisse listesi (sektörlerle)
    sector_symbols = {
        "Banka": ["GARAN.IS", "AKBNK.IS", "ISCTR.IS", "YKBNK.IS", "VAKBN.IS", "HALKB.IS"],
        "Holding": ["SAHOL.IS", "KCHOL.IS", "DOAS.IS"],
        "Teknoloji": ["ASELS.IS", "HEKTS.IS"],
        "Enerji": ["TUPRS.IS", "AEGAZ.IS"],
        "Metal": ["EREGL.IS", "KRDMD.IS"],
        "Madencilik": ["KOZAL.IS", "KOZAA.IS"],
        "Perakende": ["BIMAS.IS", "MGROS.IS", "SOKM.IS"],
        "Otomotiv": ["TOASO.IS", "FROTO.IS", "OTKAR.IS"],
        "İlaç": ["MPARK.IS", "GENTS.IS"],
        "Telekom": ["TTKOM.IS", "TRKCM.IS"],
        "Gıda": ["ULKER.IS"],
        "İçecek": ["CCOLA.IS"],
        "Cam": ["SISE.IS"],
        "Havacılık": ["THYAO.IS", "PGSUS.IS"],
        "Petrokimya": ["PETKM.IS"],
    }
    
    all_symbols = []
    for syms in sector_symbols.values():
        all_symbols.extend(syms)
    
    analyzer = TechnicalAnalyzer(symbols=list(set(all_symbols)))
    data = analyzer.fetch_all()
    
    sector_perf = {}
    for sector, syms in sector_symbols.items():
        sector_scores = []
        for sym in syms:
            if sym in data:
                sector_scores.append(data[sym].technical_score)
        
        if sector_scores:
            avg_score = sum(sector_scores) / len(sector_scores)
            sector_perf[sector] = round(avg_score, 3)
    
    # Sırala
    sorted_sectors = dict(sorted(sector_perf.items(), key=lambda x: x[1], reverse=True))
    return sorted_sectors