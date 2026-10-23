// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Signal _$SignalFromJson(Map<String, dynamic> json) {
  return Signal(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    direction: json['direction'] as String,
    confidence: (json['confidence'] as num).toDouble(),
    components: Map<String, dynamic>.from(json['components'] as Map? ?? {}),
    modelVersion: json['modelVersion'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

Map<String, dynamic> _$SignalToJson(Signal instance) {
  return {
    'id': instance.id,
    'date': instance.date.toIso8601String(),
    'direction': instance.direction,
    'confidence': instance.confidence,
    'components': instance.components,
    'modelVersion': instance.modelVersion,
    'createdAt': instance.createdAt.toIso8601String(),
  };
}