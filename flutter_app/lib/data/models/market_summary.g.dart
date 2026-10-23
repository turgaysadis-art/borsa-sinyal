// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MarketSummary _$MarketSummaryFromJson(Map<String, dynamic> json) {
  return MarketSummary(
    timestamp: DateTime.parse(json['timestamp'] as String),
    indices: Map<String, dynamic>.from(json['indices'] as Map),
    sectors: Map<String, double>.from((json['sectors'] as Map).map((k, v) => MapEntry(k as String, (v as num).toDouble()))),
    topGainers: (json['top_gainers'] as List).map((e) => StockSnapshot.fromJson(e as Map<String, dynamic>)).toList(),
    topLosers: (json['top_losers'] as List).map((e) => StockSnapshot.fromJson(e as Map<String, dynamic>)).toList(),
    mostActive: (json['most_active'] as List).map((e) => StockSnapshot.fromJson(e as Map<String, dynamic>)).toList(),
    neutral: (json['neutral'] as List).map((e) => StockSnapshot.fromJson(e as Map<String, dynamic>)).toList(),
    advancing: (json['advancing'] as num).toInt(),
    declining: (json['declining'] as num).toInt(),
    unchanged: (json['unchanged'] as num).toInt(),
    totalVolume: (json['total_volume'] as num).toInt(),
    marketBreadth: (json['market_breadth'] as num).toDouble(),
    totalStocks: (json['total_stocks'] as num).toInt(),
  );
}

Map<String, dynamic> _$MarketSummaryToJson(MarketSummary instance) {
  return {
    'timestamp': instance.timestamp.toIso8601String(),
    'indices': instance.indices,
    'sectors': instance.sectors,
    'top_gainers': instance.topGainers.map((e) => e.toJson()).toList(),
    'top_losers': instance.topLosers.map((e) => e.toJson()).toList(),
    'most_active': instance.mostActive.map((e) => e.toJson()).toList(),
    'neutral': instance.neutral.map((e) => e.toJson()).toList(),
    'advancing': instance.advancing,
    'declining': instance.declining,
    'unchanged': instance.unchanged,
    'total_volume': instance.totalVolume,
    'market_breadth': instance.marketBreadth,
    'total_stocks': instance.totalStocks,
  };
}

StockSnapshot _$StockSnapshotFromJson(Map<String, dynamic> json) {
  return StockSnapshot(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    changePct: (json['change_pct'] as num).toDouble(),
    volume: (json['volume'] as num).toInt(),
    volumeAvg: (json['volume_avg'] as num).toInt(),
    sector: json['sector'] as String,
    marketCap: (json['market_cap'] as num?)?.toDouble(),
  );
}

Map<String, dynamic> _$StockSnapshotToJson(StockSnapshot instance) {
  return {
    'symbol': instance.symbol,
    'name': instance.name,
    'price': instance.price,
    'change': instance.change,
    'change_pct': instance.changePct,
    'volume': instance.volume,
    'volume_avg': instance.volumeAvg,
    'sector': instance.sector,
    'market_cap': instance.marketCap,
  };
}