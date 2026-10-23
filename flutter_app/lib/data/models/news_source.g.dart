// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_source.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsSource _$NewsSourceFromJson(Map<String, dynamic> json) {
  return NewsSource(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    url: json['url'] as String,
    enabled: json['enabled'] as bool? ?? true,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.8,
    config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
    tags: List<String>.from(json['tags'] as List? ?? []),
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    lastFetchedAt: json['lastFetchedAt'] != null ? DateTime.parse(json['lastFetchedAt'] as String) : null,
    lastError: json['lastError'] as String?,
  );
}

Map<String, dynamic> _$NewsSourceToJson(NewsSource instance) {
  return {
    'id': instance.id,
    'name': instance.name,
    'type': instance.type,
    'url': instance.url,
    'enabled': instance.enabled,
    'weight': instance.weight,
    'config': instance.config,
    'tags': instance.tags,
    'createdAt': instance.createdAt?.toIso8601String(),
    'updatedAt': instance.updatedAt?.toIso8601String(),
    'lastFetchedAt': instance.lastFetchedAt?.toIso8601String(),
    'lastError': instance.lastError,
  };
}