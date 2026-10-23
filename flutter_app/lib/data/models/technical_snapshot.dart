// ==========================================
// BORSA SİNYAL FLUTTER - TECHNICAL SNAPSHOT MODEL
// ==========================================
import 'package:freezed_annotation/freezed_annotation.dart';

part 'technical_snapshot.freezed.dart';
part 'technical_snapshot.g.dart';

@freezed
class TechnicalSnapshot with _$TechnicalSnapshot {
  const factory TechnicalSnapshot({
    required String symbol,
    required DateTime timestamp,
    required double close,
    required double change,
    required double changePct,
    required List<double> sparklineData,
    required double ema5,
    required double ema21,
    required double ema50,
    required double ema200,
    required double distEma5Pct,
    required double distEma21Pct,
    required double distEma50Pct,
    required double distEma200Pct,
    required String trendShort,
    required String trendMedium,
    required String trendLong,
    required double rsi14,
    required double macd,
    required double macdSignal,
    required double macdHistogram,
    required int volume,
    required int volumeAvg20,
    required double volumeRatio,
    required double resistance20,
    required double support20,
    required double technicalScore,
    required String summary,
  }) = _TechnicalSnapshot;

  factory TechnicalSnapshot.fromJson(Map<String, dynamic> json) => _$TechnicalSnapshotFromJson(json);
  
  const TechnicalSnapshot._();
  
  // Helper getters
  bool get isTrendUp => trendLong == 'UP';
  bool get isTrendDown => trendLong == 'DOWN';
  
  Color get trendColor {
    switch (trendLong) {
      case 'UP': return const Color(0xFF2E7D32);
      case 'DOWN': return const Color(0xFFD32F2F);
      default: return const Color(0xFFED6C02);
    }
  }
  
  String get trendLabel {
    switch (trendLong) {
      case 'UP': return 'YÜKSELİŞ';
      case 'DOWN': return 'DÜŞÜŞ';
      default: return 'YATAY';
    }
  }
}