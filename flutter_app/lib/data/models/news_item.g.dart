// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsItem _$NewsItemFromJson(Map<String, dynamic> json) {
  return NewsItem(
    id: json['id'] as String,
    sourceId: json['sourceId'] as String,
    title: json['title'] as String,
    summary: json['summary'] as String?,
    content: json['content'] as String?,
    url: json['url'] as String,
    author: json['author'] as String?,
    tags: List<String>.from(json['tags'] as List? ?? []),
    publishedAt: DateTime.parse(json['publishedAt'] as String),
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt'] as String) : null,
    sentimentScore: (json['sentimentScore'] as num?)?.toDouble(),
    relevantTickers: List<String>.from(json['relevantTickers'] as List? ?? []),
  );
}

Map<String, dynamic> _$NewsItemToJson(NewsItem instance) {
  return {
    'id': instance.id,
    'sourceId': instance.sourceId,
    'title': instance.title,
    'summary': instance.summary,
    'content': instance.content,
    'url': instance.url,
    'author': instance.author,
    'tags': instance.tags,
    'publishedAt': instance.publishedAt.toIso8601String(),
    'fetchedAt': instance.fetchedAt.toIso8601String(),
    'processedAt': instance.processedAt?.toIso8601String(),
    'sentimentScore': instance.sentimentScore,
    'relevantTickers': instance.relevantTickers,
  };
}