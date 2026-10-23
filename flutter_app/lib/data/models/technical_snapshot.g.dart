// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technical_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicalSnapshot _$TechnicalSnapshotFromJson(Map<String, dynamic> json) {
  return TechnicalSnapshot(
    symbol: json['symbol'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    close: (json['close'] as num).toDouble(),
    change: (json['change'] as num).toDouble(),
    changePct: (json['change_pct'] as num).toDouble(),
    sparklineData: List<double>.from((json['sparkline_data'] as List).map((e) => (e as num).toDouble())),
    ema5: (json['ema_5'] as num).toDouble(),
    ema21: (json['ema_21'] as num).toDouble(),
    ema50: (json['ema_50'] as num).toDouble(),
    ema200: (json['ema_200'] as num).toDouble(),
    distEma5Pct: (json['dist_ema5_pct'] as num).toDouble(),
    distEma21Pct: (json['dist_ema21_pct'] as num).toDouble(),
    distEma50Pct: (json['dist_ema50_pct'] as num).toDouble(),
    distEma200Pct: (json['dist_ema200_pct'] as num).toDouble(),
    trendShort: json['trend_short'] as String,
    trendMedium: json['trend_medium'] as String,
    trendLong: json['trend_long'] as String,
    rsi14: (json['rsi_14'] as num).toDouble(),
    macd: (json['macd'] as num).toDouble(),
    macdSignal: (json['macd_signal'] as num).toDouble(),
    macdHistogram: (json['macd_histogram'] as num).toDouble(),
    volume: (json['volume'] as num).toInt(),
    volumeAvg20: (json['volume_avg_20'] as num).toInt(),
    volumeRatio: (json['volume_ratio'] as num).toDouble(),
    resistance20: (json['resistance_20'] as num).toDouble(),
    support20: (json['support_20'] as num).toDouble(),
    technicalScore: (json['technical_score'] as num).toDouble(),
    summary: json['summary'] as String,
  );
}

Map<String, dynamic> _$TechnicalSnapshotToJson(TechnicalSnapshot instance) {
  return {
    'symbol': instance.symbol,
    'timestamp': instance.timestamp.toIso8601String(),
    'close': instance.close,
    'change': instance.change,
    'change_pct': instance.changePct,
    'sparkline_data': instance.sparklineData,
    'ema_5': instance.ema5,
    'ema_21': instance.ema21,
    'ema_50': instance.ema50,
    'ema_200': instance.ema200,
    'dist_ema5_pct': instance.distEma5Pct,
    'dist_ema21_pct': instance.distEma21Pct,
    'dist_ema50_pct': instance.distEma50Pct,
    'dist_ema200_pct': instance.distEma200Pct,
    'trend_short': instance.trendShort,
    'trend_medium': instance.trendMedium,
    'trend_long': instance.trendLong,
    'rsi_14': instance.rsi14,
    'macd': instance.macd,
    'macd_signal': instance.macdSignal,
    'macd_histogram': instance.macdHistogram,
    'volume': instance.volume,
    'volume_avg_20': instance.volumeAvg20,
    'volume_ratio': instance.volumeRatio,
    'resistance_20': instance.resistance20,
    'support_20': instance.support20,
    'technical_score': instance.technicalScore,
    'summary': instance.summary,
  };
}