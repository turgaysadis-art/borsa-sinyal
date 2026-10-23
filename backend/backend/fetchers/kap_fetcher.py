# ==========================================
# BORSA SİNYAL BACKEND - KAP FETCHER
# ==========================================
from __future__ import annotations

import hashlib
import logging
from datetime import datetime, timedelta, timezone
from typing: Optional

import httpx

from backend.config import get_settings
from backend.models import NewsItem, NewsSource, SourceType

logger = logging.getLogger(__name__)


class KAPFetcher:
    def __init__(self, timeout: int = 30):
        settings = get_settings()
        self.api_key = settings.kap_api_key
        self.base_url = settings.kap_base_url
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(timeout),
            headers={
                "Authorization": f"Bearer {self.api_key}" if self.api_key else "",
                "Accept": "application/json",
                "User-Agent": "BorsaSignalBot/1.0",
            },
        ) if self.api_key else None
    
    async def fetch(self, source: NewsSource) -> list[NewsItem]:
        if not source.enabled or not self.client:
            return []
        
        try:
            logger.info(f"Fetching KAP: {source.name}")
            
            # Son 24 saat
            from_date = (datetime.now(timezone.utc) - timedelta(hours=25)).strftime("%Y-%m-%d")
            
            response = await self.client.get(
                f"{self.base_url}/disclosure",
                params={
                    "fromDate": from_date,
                    "toDate": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
                    "page": 1,
                    "pageSize": 100,
                },
            )
            response.raise_for_status()
            data = response.json()
            
            items = []
            for disclosure in data.get("items", []):
                item = self._parse_disclosure(disclosure, source)
                if item:
                    items.append(item)
            
            logger.info(f"Fetched {len(items)} disclosures from KAP")
            return items
            
        except Exception as e:
            logger.error(f"Error fetching KAP: {e}")
            raise
    
    def _parse_disclosure(self, disclosure: dict, source: NewsSource) -> Optional[NewsItem]:
        try:
            title = disclosure.get("title", "").strip()
            if not title:
                return None
            
            disclosure_id = disclosure.get("disclosureIndex", "")
            url = f"https://www.kap.org.tr/tr/Bildirim/{disclosure_id}" if disclosure_id else ""
            
            summary = disclosure.get("summary", "").strip()
            published_at_str = disclosure.get("publishDate", "")
            
            try:
                published_at = datetime.fromisoformat(published_at_str.replace("Z", "+00:00"))
            except Exception:
                published_at = datetime.now(timezone.utc)
            
            # Ticker'ları çıkar
            tickers = []
            for related in disclosure.get("relatedStocks", []):
                code = related.get("stockCode", "").strip()
                if code:
                    tickers.append(code.upper())
            
            item_id = hashlib.md5(f"kap_{disclosure_id}".encode()).hexdigest()[:16]
            
            return NewsItem(
                id=item_id,
                source_id=source.id,
                title=title,
                summary=summary or None,
                content=summary or None,
                url=url,
                author="KAP",
                tags=["kap", "bildirim"] + tickers,
                published_at=published_at,
                fetched_at=datetime.now(timezone.utc),
                relevant_tickers=tickers,
            )
            
        except Exception as e:
            logger.warning(f"Error parsing KAP disclosure: {e}")
            return None
    
    async def close(self):
        if self.client:
            await self.client.aclose()