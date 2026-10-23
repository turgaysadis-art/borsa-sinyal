# ==========================================
# BORSA SİNYAL BACKEND - SES/VİDEO ANALİZİ
# ==========================================
from __future__ import annotations

import logging
import os
import tempfile
from dataclasses import dataclass
from datetime import datetime, timezone
from typing: Optional

logger = logging.getLogger(__name__)

# Optional imports
try:
    import yt_dlp
    YT_DLP_AVAILABLE = True
except ImportError:
    YT_DLP_AVAILABLE = False
    logger.warning("yt-dlp not installed. Audio analysis disabled.")

try:
    from faster_whisper import WhisperModel
    WHISPER_AVAILABLE = True
except ImportError:
    WHISPER_AVAILABLE = False
    logger.warning("faster-whisper not installed. Audio analysis disabled.")


@dataclass
class AudioAnalysisResult:
    video_id: str
    title: str
    channel: str
    duration_seconds: int
    transcript: str
    summary: str
    sentiment_score: float
    keywords: list[str]
    processed_at: str


class AudioAnalyzer:
    """YouTube videolarını indir, transkribe et, analiz et."""
    
    def __init__(self, model_size: str = "base", device: str = "cpu"):
        """
        model_size: tiny, base, small, medium, large-v3
        device: cpu, cuda
        """
        self.model_size = model_size
        self.device = device
        self.model = None
        self._whisper_ready = False
    
    def _ensure_whisper(self):
        if self._whisper_ready:
            return
        if not WHISPER_AVAILABLE:
            raise RuntimeError("faster-whisper not installed")
        
        logger.info(f"Loading Whisper model: {self.model_size} on {self.device}")
        self.model = WhisperModel(
            self.model_size,
            device=self.device,
            compute_type="int8" if self.device == "cpu" else "float16",
        )
        self._whisper_ready = True
    
    async def analyze_youtube_video(self, video_url: str, sentiment_analyzer=None) -> Optional[AudioAnalysisResult]:
        """YouTube videosunu analiz et."""
        if not YT_DLP_AVAILABLE or not WHISPER_AVAILABLE:
            return None
        
        video_id = self._extract_video_id(video_url)
        if not video_id:
            return None
        
        # Video bilgilerini al
        info = await self._get_video_info(video_url)
        if not info:
            return None
        
        # Süre kontrolü (çok uzunsa atla - örn: > 45 dk)
        max_duration = 2700  # 45 dakika
        if info.get("duration", 0) > max_duration:
            logger.info(f"Video too long, skipping: {video_id} ({info['duration']}s)")
            return None
        
        # Ses dosyasını indir
        audio_path = await self._download_audio(video_url, video_id)
        if not audio_path:
            return None
        
        try:
            # Transkribe et
            transcript = self._transcribe(audio_path)
            if not transcript.strip():
                return None
            
            # Analiz et
            summary = self._summarize(transcript)
            
            if sentiment_analyzer:
                sentiment = sentiment_analyzer.analyze(transcript)
                keywords = sentiment_analyzer.processor.extract_keywords(transcript, top_k=15)
            else:
                sentiment = 0.0
                keywords = []
            
            return AudioAnalysisResult(
                video_id=video_id,
                title=info.get("title", ""),
                channel=info.get("uploader", ""),
                duration_seconds=info.get("duration", 0),
                transcript=transcript[:5000],  # İlk 5000 karakter
                summary=summary,
                sentiment_score=sentiment,
                keywords=keywords,
                processed_at=datetime.now(timezone.utc).isoformat(),
            )
        
        finally:
            # Geçici dosyayı sil
            try:
                os.unlink(audio_path)
            except Exception:
                pass
    
    def _extract_video_id(self, url: str) -> Optional[str]:
        import re
        patterns = [
            r"(?:v=|\/)([0-9A-Za-z_-]{11}).*",
            r"youtu\.be\/([0-9A-Za-z_-]{11})",
        ]
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        return None
    
    async def _get_video_info(self, url: str) -> Optional[dict]:
        if not YT_DLP_AVAILABLE:
            return None
        
        ydl_opts = {"quiet": True, "no_warnings": True, "extract_flat": False}
        try:
            import yt_dlp
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                return ydl.extract_info(url, download=False)
        except Exception as e:
            logger.warning(f"Failed to get video info: {e}")
            return None
    
    async def _download_audio(self, url: str, video_id: str) -> Optional[str]:
        if not YT_DLP_AVAILABLE:
            return None
        
        # Geçici dosya yolu
        temp_dir = tempfile.gettempdir()
        output_path = os.path.join(temp_dir, f"yt_{video_id}.%(ext)s")
        
        ydl_opts = {
            "format": "bestaudio/best",
            "outtmpl": output_path,
            "quiet": True,
            "no_warnings": True,
            "postprocessors": [{
                "key": "FFmpegExtractAudio",
                "preferredcodec": "wav",
                "preferredquality": "192",
            }],
        }
        try:
            import yt_dlp
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                ydl.download([url])
            return os.path.join(temp_dir, f"yt_{video_id}.wav")
        except Exception as e:
            logger.warning(f"Audio download failed: {e}")
            return None
    
    def _transcribe(self, audio_path: str) -> str:
        self._ensure_whisper()
        segments, _ = self.model.transcribe(
            audio_path,
            language="tr",
            beam_size=5,
            vad_filter=True,
            vad_parameters=dict(min_silence_duration_ms=500),
        )
        return " ".join([seg.text for seg in segments])
    
    def _summarize(self, text: str, max_sentences: int = 5) -> str:
        """Basit özet: ilk cümleler + en önemli cümleler."""
        import re
        sentences = re.split(r'[.!?]+', text)
        sentences = [s.strip() for s in sentences if len(s.strip()) > 20]
        return " ".join(sentences[:max_sentences])