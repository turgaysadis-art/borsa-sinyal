# Borsa Sinyal Uygulaması

Türkiye borsası (BIST) için haber + teknik analiz tabanlı yön tahmini yapan, Flutter + Python mimarisinde çalışan açık kaynak uygulama.

## 🏗 Mimari

```
borsa-sinyal/
├── backend/           # Python: Veri toplama + ML + API
│   ├── fetchers/      # RSS, YouTube, KAP çekiciler
│   ├── nlp/           # Türkçe NLP, Sentiment, TF-IDF + XGBoost
│   ├── technical/     # EMA, RSI, MACD, Destek/Direnç
│   ├── fusion/        # Hibrit sinyal motoru (Haber + Teknik + KAP + Ses)
│   ├── scheduler/     # APScheduler (periyodik fetch + sinyal üretimi)
│   └── api/           # FastAPI endpoints
├── flutter_app/       # Flutter: iOS/Android/Web/Desktop
│   ├── lib/
│   │   ├── core/      # Tema, DI, Isar DB, Network
│   │   ├── data/      # Models, Repositories, Providers
│   │   ├── features/  # Home, News, Technical, Market, Signal, Settings, Sources
│   │   └── shared/    # Widgets, Utils
└── shared/            # Ortak JSON schema
```

## 🚀 Hızlı Başlangıç

### Backend (Python 3.11+)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env
# .env dosyasını düzenleyin (API key'ler)
python -m backend.main
# API: http://localhost:8000
# Docs: http://localhost:8000/docs
```

**Gerekli API Key'ler (Ücretsiz):**
| Servis | Nereden | Limit |
|--------|---------|-------|
| KAP | https://www.kap.org.tr/tr/api | Günlük 1000 istek |
| YouTube Data API v3 | Google Cloud Console | Günlük 10.000 birim |
| RSS | Herhangi bir feed | Sınırsız |

### Flutter (3.19+)

```bash
cd flutter_app
flutter pub get
flutter run -d windows  # veya macos, linux, chrome, android, ios
```

**Bağımlılıklar:**
- `flutter_riverpod` - State management
- `go_router` - Navigation
- `isar` - Local database
- `dio` - HTTP client
- `fl_chart` - Grafikler
- `wakelock_plus` - Ekran açık kalma
- `webview_flutter` - Haber detayında kaynak görüntüleme

## 📱 Özellikler

### Ana Ekran (Home)
- **Piyasa Özeti Barı**: BIST30, Gümüş, Altın, Petrol (mini sparkline + EMA200/RSI/Trend)
- **Genel BIST Durumu**: Yükselen/Düşen/Dengeli hisseler + Sektör performans + Endeksler
- **Haber Kaydırıcı**: Mynet tarzı PageView carousel (sentiment rengi, kaynak/tarih/kategori badge)
- **Günlük Sinyal**: UP/DOWN/FLAT + Güven % + Açıklama
- **Sinyal Geçmişi**: Filtrelenebilir liste
- **Tüm Haberler**: Infinite scroll liste

### Detay Sayfaları
- **Haber Detayı**: Tam içerik, WebView fallback, teknik etki analizi, ilgili haberler, kaynağa git
- **Teknik Analiz Detayı**: Grafik, EMA/RSI/MACD, Hacim, Destek/Direnç, Osilatör bölgeleri
- **Genel Piyasa Özeti**: Tüm hisseler, sektörler, endeksler, piyasa genişliği
- **Sinyal Detayı**: Bileşen skorları, sürücüler/riskler, kaynak dağılımı
- **Kaynak Yönetimi**: Ekle/sil/test et, RSS/YouTube/KAP desteği

### Ayarlar
- **Tema**: Light / Dark / Custom (renk seçici)
- **Wake Lock**: Ekran açık kalma (uygulama açıkken)
- **Yedek Al/Yükle**: JSON export/import
- **Backend URL**: Geliştirme/production değiştirme

## 🔧 Geliştirme

### Backend Kod Kalitesi
```bash
cd backend
ruff check .          # Lint
ruff format .         # Format
mypy backend/         # Type check
pytest                # Testler
```

### Flutter Kod Kalitesi
```bash
cd flutter_app
dart analyze          # Analyze
dart format .         # Format
flutter test          # Testler
flutter pub run build_runner build --delete-conflicting-outputs  # Code gen
```

### Kod Üretimi (Freezed/Json/Isar/Riverpod)
```bash
cd flutter_app
flutter pub run build_runner build --delete-conflicting-outputs
# Watch mode: flutter pub run build_runner watch --delete-conflicting-outputs
```

## 📊 Model Akışı

```
Veri Kaynağı          → İşleme                    → Çıktı
──────────────────────────────────────────────────────────────
RSS/YouTube/KAP      → Temizleme + Kategori      → NewsItem
                     → Sentiment (-1, +1)         → sentiment_score
                     → Ticker çıkarma             → relevant_tickers
──────────────────────────────────────────────────────────────
yfinance (BIST30,    → EMA 5/21/50/200           → TechnicalSnapshot
  Altın, Petrol)     → RSI, MACD, Hacim           → technical_score
                     → Destek/Direnç              → trend_long
──────────────────────────────────────────────────────────────
Haber + Teknik + KAP → Fusion Engine             → Signal (UP/DOWN/FLAT)
                     → Ağırlıklı toplam           → confidence
                     → ML meta-öğrenme            → explanation
```

## ⚙️ Konfigürasyon (.env)

```env
# API Keys
KAP_API_KEY=your_key
YOUTUBE_API_KEY=your_key

# RSS Feeds (name|url|weight|enabled)
RSS_FEEDS=BloombergHT|https://www.bloomberght.com/rss/ekonomi.xml|1.0|true,...

# Model
SIGNAL_THRESHOLD=0.55
FETCH_INTERVAL_MINUTES=30

# Fusion Weights (toplam 1.0)
WEIGHT_NEWS=0.30
WEIGHT_KAP=0.15
WEIGHT_TECHNICAL=0.35
WEIGHT_AUDIO=0.10
WEIGHT_MACRO=0.10
```

## 📄 Lisans

MIT License - Dilediğiniz gibi kullanın, geliştirin.

## 🤝 Katkı

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Commit atın (`git commit -am 'Yeni özellik eklendi'`)
4. Push yapın (`git push origin feature/yeni-ozellik`)
5. Pull Request açın

## 📞 İletişim

Sorular için: GitHub Issues