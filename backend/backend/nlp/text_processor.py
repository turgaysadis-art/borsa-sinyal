# ==========================================
# BORSA SİNYAL BACKEND - METİN İŞLEME
# ==========================================
from __future__ import annotations

import logging
import re
import unicodedata
from typing import List

import nltk
from nltk.corpus import stopwords
from nltk.stem import SnowballStemmer
from nltk.tokenize import word_tokenize

logger = logging.getLogger(__name__)

# NLTK verilerini indir (ilk çalıştırmada)
_nltk_initialized = False

def _ensure_nltk():
    global _nltk_initialized
    if _nltk_initialized:
        return
    try:
        nltk.data.find("tokenizers/punkt")
    except LookupError:
        nltk.download("punkt", quiet=True)
    try:
        nltk.data.find("tokenizers/punkt_tab")
    except LookupError:
        nltk.download("punkt_tab", quiet=True)
    try:
        nltk.data.find("corpora/stopwords")
    except LookupError:
        nltk.download("stopwords", quiet=True)
    _nltk_initialized = True


class TurkishTextProcessor:
    """Türkçe metin ön işleme sınıfı."""
    
    def __init__(self):
        _ensure_nltk()
        self.stemmer = SnowballStemmer("turkish")
        self.stop_words = set(stopwords.words("turkish"))
        
        # Finans özel stop words
        self.finance_stop_words = {
            "açıkladı", "bildirdi", "bildirim", "kamuoyu", "aydınlatma",
            "platformu", "kap", "şirket", "anonim", "şirketi", "a.ş",
            "inc", "ltd", "stü", "holding", "grup", "grubu",
            "gün", "hafta", "ay", "yıl", "bugün", "dün", "yarın",
            "saat", "dakika", "saniye", "zaman", "tarih",
            "ile", "ve", "veya", "ama", "fakat", "lakin",
            "için", "olarak", "gibi", "kadar", "daha", "en",
            "bu", "şu", "o", "bunlar", "şunlar", "onlar",
            "ben", "sen", "biz", "siz", "benim", "senin",
            "olarak", "yapıldı", "yapılan", "yapacak", "eden",
        }
        self.stop_words.update(self.finance_stop_words)
        
        # Türkçe karakter normalizasyonu
        self.tr_chars = str.maketrans({
            "ı": "i", "ğ": "g", "ü": "u", "ş": "s", "ö": "o", "ç": "c",
            "İ": "i", "Ğ": "g", "Ü": "u", "Ş": "s", "Ö": "o", "Ç": "c",
        })
    
    def clean(self, text: str) -> str:
        """Metni temizle ve normalize et."""
        if not text:
            return ""
        
        # Unicode normalize
        text = unicodedata.normalize("NFKC", text)
        
        # Küçük harfe çevir
        text = text.lower()
        
        # Türkçe karakterleri ASCII'ye çevir
        text = text.translate(self.tr_chars)
        
        # URL'leri temizle
        text = re.sub(r"https?://\S+|www\.\S+", "", text)
        
        # E-posta adreslerini temizle
        text = re.sub(r"\S+@\S+", "", text)
        
        # Özel karakterleri temizle (noktalama işaretlerini tut)
        text = re.sub(r"[^\w\s\.\,\!\?\:\;\-\(\)]", " ", text)
        
        # Çoklu boşlukları tek boşluğa indir
        text = re.sub(r"\s+", " ", text)
        
        return text.strip()
    
    def tokenize(self, text: str) -> List[str]:
        """Metni token'lara ayır."""
        _ensure_nltk()
        try:
            tokens = word_tokenize(text, language="turkish")
        except:
            # Fallback: basit split
            tokens = text.split()
        return tokens
    
    def remove_stopwords(self, tokens: List[str]) -> List[str]:
        """Stop word'leri çıkar."""
        return [t for t in tokens if t not in self.stop_words and len(t) > 2]
    
    def stem(self, tokens: List[str]) -> List[str]:
        """Kök bulma (stemming)."""
        return [self.stemmer.stem(t) for t in tokens]
    
    def process(self, text: str) -> str:
        """Tam işleme pipeline'ı: clean -> tokenize -> stopwords -> stem -> join."""
        cleaned = self.clean(text)
        tokens = self.tokenize(cleaned)
        tokens = self.remove_stopwords(tokens)
        tokens = self.stem(tokens)
        return " ".join(tokens)
    
    def extract_keywords(self, text: str, top_k: int = 10) -> List[str]:
        """Metinden anahtar kelimeleri çıkar (basit frekans tabanlı)."""
        processed = self.process(text)
        tokens = processed.split()
        freq = {}
        for token in tokens:
            freq[token] = freq.get(token, 0) + 1
        sorted_tokens = sorted(freq.items(), key=lambda x: x[1], reverse=True)
        return [token for token, _ in sorted_tokens[:top_k]]


# Global instance
_processor: TurkishTextProcessor | None = None


def get_processor() -> TurkishTextProcessor:
    global _processor
    if _processor is None:
        _processor = TurkishTextProcessor()
    return _processor