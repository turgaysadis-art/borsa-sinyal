# ==========================================
# BORSA SİNYAL BACKEND - RSS FETCHER
# ==========================================
from __future__ import annotations

import hashlib
import logging
import re
from datetime import datetime, timezone
from typing: Optional
from urllib.parse import urljoin

import feedparser
import httpx
from bs4 import BeautifulSoup

from backend.config import get_settings
from backend.models import NewsItem, NewsSource

logger = logging.getLogger(__name__)


class RSSFetcher:
    def __init__(self, timeout: int = 30):
        self.timeout = timeout
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(timeout),
            headers={"User-Agent": "Mozilla/5.0 (compatible; BorsaSignalBot/1.0)"},
            follow_redirects=True,
        )
    
    async def fetch(self, source: NewsSource) -> list[NewsItem]:
        """RSS feed'inden haberleri çek."""
        if not source.enabled:
            return []
        
        try:
            logger.info(f"Fetching RSS: {source.name} ({source.url})")
            
            # Feedparser ile çek
            feed = await self._parse_feed(source.url)
            
            if feed.bozo and feed.bozo_exception:
                logger.warning(f"RSS parse warning for {source.name}: {feed.bozo_exception}")
            
            items = []
            for entry in feed.entries:
                item = self._parse_entry(entry, source)
                if item:
                    items.append(item)
            
            logger.info(f"Fetched {len(items)} items from {source.name}")
            return items
            
        except Exception as e:
            logger.error(f"Error fetching RSS {source.name}: {e}")
            raise
    
    async def _parse_feed(self, url: str) -> feedparser.FeedParserDict:
        # Önce HTTP ile çek (bazı siteler feedparser'ın direkt erişimini engelliyor)
        try:
            response = await self.client.get(url)
            response.raise_for_status()
            return feedparser.parse(response.text)
        except Exception:
            # Fallback: feedparser'ın kendi fetcher'ı
            return feedparser.parse(url)
    
    def _parse_entry(self, entry: feedparser.FeedParserDict, source: NewsSource) -> Optional[NewsItem]:
        try:
            # URL
            url = entry.get("link", "")
            if not url:
                return None
            
            # Başlık
            title = entry.get("title", "").strip()
            if not title:
                return None
            
            # Özet/İçerik
            summary = self._clean_html(entry.get("summary", ""))
            content = self._clean_html(entry.get("content", [{}])[0].get("value", "") if entry.get("content") else "")
            
            # Yazar
            author = entry.get("author", "").strip() or None
            
            # Etiketler
            tags = [tag.term for tag in entry.get("tags", []) if tag.get("term")]
            
            # Yayın tarihi
            published_at = self._parse_datetime(entry)
            
            # Benzersiz ID (URL hash)
            item_id = hashlib.md5(url.encode()).hexdigest()[:16]
            
            return NewsItem(
                id=item_id,
                source_id=source.id,
                title=title,
                summary=summary or None,
                content=content or None,
                url=url,
                author=author,
                tags=tags,
                published_at=published_at,
                fetched_at=datetime.now(timezone.utc),
            )
            
        except Exception as e:
            logger.warning(f"Error parsing entry from {source.name}: {e}")
            return None
    
    def _clean_html(self, html: str) -> str:
        if not html:
            return ""
        soup = BeautifulSoup(html, "lxml")
        text = soup.get_text(separator=" ", strip=True)
        # Çoklu boşlukları tek boşluğa indir
        text = re.sub(r"\s+", " ", text)
        return text
    
    def _parse_datetime(self, entry: feedparser.FeedParserDict) -> datetime:
        """Feedparser'dan datetime parse et."""
        for field in ("published_parsed", "updated_parsed", "created_parsed"):
            parsed = entry.get(field)
            if parsed:
                try:
                    return datetime(*parsed[:6], tzinfo=timezone.utc)
                except Exception:
                    pass
        
        # String olarak gelmiş olabilir
        for field in ("published", "updated", "created"):
            date_str = entry.get(field)
            if date_str:
                try:
                    return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
                except Exception:
                    pass
        
        return datetime.now(timezone.utc)
    
    async def close(self):
        await self.client.aclose()