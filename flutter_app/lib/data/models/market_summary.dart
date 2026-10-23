// ==========================================
// BORSA SİNYAL FLUTTER - MARKET SUMMARY MODEL
// ==========================================
import 'package:freezed_annotation/freezed_annotation.dart';

part 'market_summary.freezed.dart';
part 'market_summary.g.dart';

@freezed
class MarketSummary with _$MarketSummary {
  const factory MarketSummary({
    required DateTime timestamp,
    required Map<String, dynamic> indices,
    required Map<String, double> sectors,
    required List<StockSnapshot> topGainers,
    required List<StockSnapshot> topLosers,
    required List<StockSnapshot> mostActive,
    required List<StockSnapshot> neutral,
    required int advancing,
    required int declining,
    required int unchanged,
    required int totalVolume,
    required double marketBreadth,
    required int totalStocks,
  }) = _MarketSummary;

  factory MarketSummary.fromJson(Map<String, dynamic> json) => _$MarketSummaryFromJson(json);
  
  const MarketSummary._();
}

@freezed
class StockSnapshot with _$StockSnapshot {
  const factory StockSnapshot({
    required String symbol,
    required String name,
    required double price,
    required double change,
    required double changePct,
    required int volume,
    required int volumeAvg,
    required String sector,
    double? marketCap,
  }) = _StockSnapshot;

  factory StockSnapshot.fromJson(Map<String, dynamic> json) => _$StockSnapshotFromJson(json);
  
  const StockSnapshot._();
  
  Color get changeColor => changePct > 0 ? const Color(0xFF2E7D32) : (changePct < 0 ? const Color(0xFFD32F2F) : const Color(0xFFED6C02));
  String get changeSign => changePct > 0 ? '▲' : (changePct < 0 ? '▼' : '●');
}