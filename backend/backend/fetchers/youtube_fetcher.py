# ==========================================
# BORSA SİNYAL BACKEND - YOUTUBE FETCHER
# ==========================================
from __future__ import annotations

import hashlib
import logging
from datetime import datetime, timedelta, timezone
from typing: Optional

from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from backend.config import get_settings
from backend.models import NewsItem, NewsSource

logger = logging.getLogger(__name__)


class YouTubeFetcher:
    def __init__(self):
        settings = get_settings()
        self.api_key = settings.youtube_api_key
        self.channels = settings.parsed_youtube_channels
        self.youtube = None
        
        if self.api_key:
            try:
                self.youtube = build("youtube", "v3", developerKey=self.api_key, cache_discovery=False)
            except Exception as e:
                logger.error(f"YouTube API client creation failed: {e}")
    
    async def fetch(self, source: NewsSource) -> list[NewsItem]:
        if not source.enabled or not self.youtube:
            return []
        
        channel_id = source.config.get("channel_id")
        if not channel_id:
            logger.warning(f"No channel_id configured for YouTube source: {source.name}")
            return []
        
        try:
            logger.info(f"Fetching YouTube: {source.name} ({channel_id})")
            
            # Son 24 saatin videolarını al
            published_after = (datetime.now(timezone.utc) - timedelta(hours=25)).isoformat().replace("+00:00", "Z")
            
            request = self.youtube.search().list(
                part="snippet",
                channelId=channel_id,
                type="video",
                order="date",
                publishedAfter=published_after,
                maxResults=50,
            )
            
            response = request.execute()
            items = []
            
            for video in response.get("items", []):
                item = self._parse_video(video, source)
                if item:
                    items.append(item)
            
            logger.info(f"Fetched {len(items)} videos from {source.name}")
            return items
            
        except HttpError as e:
            logger.error(f"YouTube API error for {source.name}: {e}")
            raise
        except Exception as e:
            logger.error(f"Error fetching YouTube {source.name}: {e}")
            raise
    
    def _parse_video(self, video: dict, source: NewsSource) -> Optional[NewsItem]:
        try:
            snippet = video["snippet"]
            video_id = video["id"]["videoId"]
            url = f"https://www.youtube.com/watch?v={video_id}"
            
            title = snippet.get("title", "").strip()
            if not title:
                return None
            
            description = snippet.get("description", "").strip()
            published_at = datetime.fromisoformat(snippet["publishedAt"].replace("Z", "+00:00"))
            
            # Benzersiz ID
            item_id = hashlib.md5(url.encode()).hexdigest()[:16]
            
            # Tagleri description'dan çıkar (hashtag'ler)
            tags = [tag[1:] for tag in description.split() if tag.startswith("#")]
            
            return NewsItem(
                id=item_id,
                source_id=source.id,
                title=title,
                summary=description[:500] if description else None,
                content=description if description else None,
                url=url,
                author=snippet.get("channelTitle"),
                tags=tags,
                published_at=published_at,
                fetched_at=datetime.now(timezone.utc),
            )
            
        except Exception as e:
            logger.warning(f"Error parsing YouTube video: {e}")
            return None
    
    async def fetch_all_channels(self) -> list[NewsItem]:
        """Tüm yapılandırılmış kanallardan çek."""
        all_items = []
        for channel_id in self.channels:
            # Geçici source oluştur
            from backend.models import NewsSource, SourceType
            temp_source = NewsSource(
                id=f"yt_{channel_id}",
                name=f"YouTube:{channel_id}",
                type=SourceType.YOUTUBE,
                url=f"https://youtube.com/channel/{channel_id}",
                enabled=True,
                weight=0.7,
                config={"channel_id": channel_id},
            )
            items = await self.fetch(temp_source)
            all_items.extend(items)
        return all_items