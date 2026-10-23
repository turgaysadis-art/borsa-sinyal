# ==========================================
# BORSA SİNYAL BACKEND - MARKET ROUTES
# ==========================================
from __future__ import annotations

import concurrent.futures
from fastapi import APIRouter, Query, HTTPException
from typing import Optional
from datetime import datetime, timezone
from dataclasses import asdict

from backend.technical.indicators import TechnicalAnalyzer
from backend.api.routes.news import item_to_dict
from backend.database import get_session
from backend.models import NewsItem
from sqlalchemy import select, desc, func, or_

router = APIRouter()


# BIST hisse listesi (sektörlerle birlikte)
BIST_STOCKS = {
    # Bankacılık
    "GARAN.IS": ("Garanti BBVA", "Banka"),
    "AKBNK.IS": ("Akbank", "Banka"),
    "ISCTR.IS": ("İş Bankası", "Banka"),
    "YKBNK.IS": ("Yapı Kredi", "Banka"),
    "VAKBNK.IS": ("VakıfBank", "Banka"),
    "HALKB.IS": ("Halkbank", "Banka"),
    "TSKB.IS": ("TSKB", "Banka"),
    
    # Holding
    "SAHOL.IS": ("Sabancı Holding", "Holding"),
    "KCHOL.IS": ("Koç Holding", "Holding"),
    "DOAS.IS": ("Doğan Holding", "Holding"),
    
    # Teknoloji / Savunma
    "ASELS.IS": ("Aselsan", "Teknoloji"),
    "THYAO.IS": ("Türk Hava Yolları", "Ulaştırma"),
    "HEKTS.IS": ("Hektaş", "Teknoloji"),
    
    # Enerji / Petrol
    "TUPRS.IS": ("Tüpraş", "Enerji"),
    "PETKM.IS": ("Petkim", "Petrokimya"),
    "AEGAZ.IS": ("Aygaz", "Enerji"),
    
    # Madencilik / Metal
    "EREGL.IS": ("Ereğli Demir Çelik", "Metal"),
    "KRDMD.IS": ("Kardemir", "Metal"),
    "KOZAL.IS": ("Koza Altın", "Madencilik"),
    "KOZAA.IS": ("Koza Anadolu", "Madencilik"),
    
    # Tüketim / Perakende
    "BIMAS.IS": ("BİM", "Perakende"),
    "MGROS.IS": ("Migros", "Perakende"),
    "SOKM.IS": ("Şok Marketler", "Perakende"),
    
    # Otomotiv
    "TOASO.IS": ("Tofaş", "Otomotiv"),
    "FROTO.IS": ("Ford Otosan", "Otomotiv"),
    "OTKAR.IS": ("Otokar", "Otomotiv"),
    
    # İlaç / Sağlık
    "MPARK.IS": ("Medaş", "İlaç"),
    "GENTS.IS": ("Gen İlaç", "İlaç"),
    
    # Telekom
    "TTKOM.IS": ("Türk Telekom", "Telekom"),
    "TRKCM.IS": ("Turkcell", "Telekom"),
    
    # Diğer
    "SISE.IS": ("Şişecam", "Cam"),
    "PGSUS.IS": ("Pegasus", "Havacılık"),
    "ULKER.IS": ("Ülker", "Gıda"),
    "CCOLA.IS": ("Coca Cola İçecek", "İçecek"),
    "ANHYT.IS": ("Anadolu Hayat", "Sigorta"),
}

INDICES = {
    "XU100.IS": "BIST100",
    "XU030.IS": "BIST30",
    "XU050.IS": "BIST50",
    "XBANK.IS": "BIST Banka",
    "XHOLD.IS": "BIST Holding",
    "XTECH.IS": "BIST Teknoloji",
    "XELKT.IS": "BIST Elektrik",
    "XFINK.IS": "BIST Finansal",
    "XGIDA.IS": "BIST Gıda",
    "XULAS.IS": "BIST Ulaştırma",
    "XMESY.IS": "BIST Metal",
    "XSINE.IS": "BIST Sınai",
}


def fetch_stock_data(symbol: str):
    """Tek hisse verisi çek (yfinance)."""
    try:
        import yfinance as yf
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period="5d", interval="1d")
        info = ticker.info
        
        if len(hist) < 2:
            return None
            
        current = hist['Close'].iloc[-1]
        prev = hist['Close'].iloc[-2]
        change = current - prev
        change_pct = (change / prev * 100) if prev != 0 else 0
        volume = int(hist['Volume'].iloc[-1])
        volume_avg = int(hist['Volume'].rolling(20).mean().iloc[-1]) if len(hist) >= 20 else volume
        
        name, sector = BIST_STOCKS.get(symbol, (symbol, "Diğer"))
        
        return {
            "symbol": symbol,
            "name": name,
            "price": round(current, 2),
            "change": round(change, 2),
            "change_pct": round(change_pct, 2),
            "volume": volume,
            "volume_avg": volume_avg,
            "sector": sector,
            "market_cap": info.get('marketCap'),
        }
    except Exception as e:
        return None


def fetch_index_data(symbol: str):
    """Endeks verisi çek."""
    try:
        import yfinance as yf
        ticker = yf.Ticker(symbol)
        hist = ticker.history(period="5d", interval="1d")
        if len(hist) < 2:
            return {}
        current = hist['Close'].iloc[-1]
        prev = hist['Close'].iloc[-2]
        change_pct = ((current - prev) / prev * 100) if prev != 0 else 0
        return {
            "symbol": symbol,
            "value": round(current, 2),
            "change_pct": round(change_pct, 2),
        }
    except Exception:
        return {}


@router.get("/summary")
async def get_market_summary():
    """Genel BIST pazar özeti."""
    # Endeksleri çek
    indices = {}
    for sym, name in INDICES.items():
        data = fetch_index_data(sym)
        if data:
            indices[name] = data
    
    # Tüm hisseleri paralel çek
    stocks = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(fetch_stock_data, sym): sym for sym in BIST_STOCKS.keys()}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            if result:
                stocks.append(result)
    
    if not stocks:
        raise HTTPException(status_code=503, detail="Hisse verisi çekilemedi")
    
    # Sırala
    gainers = sorted([s for s in stocks if s["change_pct"] > 0], key=lambda x: x["change_pct"], reverse=True)[:10]
    losers = sorted([s for s in stocks if s["change_pct"] < 0], key=lambda x: x["change_pct"])[:10]
    active = sorted(stocks, key=lambda x: x["volume"], reverse=True)[:10]
    neutral = [s for s in stocks if -0.5 <= s["change_pct"] <= 0.5][:10]
    
    advancing = len([s for s in stocks if s["change_pct"] > 0.1])
    declining = len([s for s in stocks if s["change_pct"] < -0.1])
    unchanged = len(stocks) - advancing - declining
    total_vol = sum(s["volume"] for s in stocks)
    breadth = advancing / (advancing + declining) if (advancing + declining) > 0 else 0.5
    
    # Sektör performansları
    sector_perf = {}
    for sector in set(s["sector"] for s in stocks):
        sector_stocks = [s for s in stocks if s["sector"] == sector]
        if sector_stocks:
            avg_change = sum(s["change_pct"] for s in sector_stocks) / len(sector_stocks)
            sector_perf[sector] = round(avg_change, 2)
    
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "indices": indices,
        "sectors": dict(sorted(sector_perf.items(), key=lambda x: x[1], reverse=True)),
        "top_gainers": gainers,
        "top_losers": losers,
        "most_active": active,
        "neutral": neutral,
        "advancing": advancing,
        "declining": declining,
        "unchanged": unchanged,
        "total_volume": total_vol,
        "market_breadth": round(breadth, 3),
        "total_stocks": len(stocks),
    }


@router.get("/stock/{symbol}")
async def get_stock_detail(symbol: str):
    """Tek hisse detayı (teknik + temel)."""
    from backend.technical.indicators import TechnicalAnalyzer
    
    symbol = symbol.upper()
    stock_data = fetch_stock_data(symbol)
    if not stock_data:
        raise HTTPException(status_code=404, detail="Hisse bulunamadı veya veri çekilemedi")
    
    # Teknik analiz
    try:
        tech = TechnicalAnalyzer(symbols=[symbol]).analyze_symbol(symbol)
        technical = {
            "ema_5": round(tech.ema_5, 2),
            "ema_21": round(tech.ema_21, 2),
            "ema_50": round(tech.ema_50, 2),
            "ema_200": round(tech.ema_200, 2),
            "trend_short": tech.trend_short,
            "trend_medium": tech.trend_medium,
            "trend_long": tech.trend_long,
            "dist_ema5_pct": round(tech.dist_ema5_pct, 2),
            "dist_ema21_pct": round(tech.dist_ema21_pct, 2),
            "dist_ema50_pct": round(tech.dist_ema50_pct, 2),
            "dist_ema200_pct": round(tech.dist_ema200_pct, 2),
            "rsi_14": round(tech.rsi_14, 1),
            "macd": round(tech.macd, 4),
            "macd_signal": round(tech.macd_signal, 4),
            "macd_histogram": round(tech.macd_histogram, 4),
            "volume": tech.volume,
            "volume_avg_20": tech.volume_avg_20,
            "volume_ratio": round(tech.volume_ratio, 2),
            "resistance_20": round(tech.resistance_20, 2),
            "support_20": round(tech.support_20, 2),
            "technical_score": round(tech.technical_score, 3),
            "summary": tech.summary,
            "sparkline_data": tech.sparkline_data,
        }
    except Exception as e:
        technical = {"error": f"Teknik analiz hatası: {str(e)}"}
    
    return {
        "fundamental": stock_data,
        "technical": technical,
    }


@router.get("/breadth")
async def get_market_breadth():
    """Piyasa genişliği (advance/decline)."""
    stocks = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        futures = {executor.submit(fetch_stock_data, sym): sym for sym in BIST_STOCKS.keys()}
        for future in concurrent.futures.as_completed(futures):
            result = future.result()
            if result:
                stocks.append(result)
    
    if not stocks:
        raise HTTPException(status_code=503, detail="Veri çekilemedi")
    
    advancing = [s for s in stocks if s["change_pct"] > 0.1]
    declining = [s for s in stocks if s["change_pct"] < -0.1]
    unchanged = [s for s in stocks if -0.1 <= s["change_pct"] <= 0.1]
    
    # Sektör bazlı breadth
    sector_breadth = {}
    for sector in set(s["sector"] for s in stocks):
        sector_stocks = [s for s in stocks if s["sector"] == sector]
        adv = len([s for s in sector_stocks if s["change_pct"] > 0.1])
        dec = len([s for s in sector_stocks if s["change_pct"] < -0.1])
        unc = len(sector_stocks) - adv - dec
        sector_breadth[sector] = {
            "advancing": adv,
            "declining": dec,
            "unchanged": unc,
            "breadth": round(adv / (adv + dec), 3) if (adv + dec) > 0 else 0.5,
        }
    
    return {
        "total": len(stocks),
        "advancing": len(advancing),
        "declining": len(declining),
        "unchanged": len(unchanged),
        "breadth": round(len(advancing) / (len(advancing) + len(declining)), 3) if (len(advancing) + len(declining)) > 0 else 0.5,
        "by_sector": sector_breadth,
    }