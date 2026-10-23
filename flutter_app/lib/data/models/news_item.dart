// ==========================================
// BORSA SİNYAL FLUTTER - NEWS ITEM MODEL
// ==========================================
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'news_item.freezed.dart';
part 'news_item.g.dart';

@freezed
@Collection()
class NewsItem with _$NewsItem {
  const factory NewsItem({
    @Default('') @Id() String id,
    required String sourceId,
    required String title,
    String? summary,
    String? content,
    required String url,
    String? author,
    @Default([]) List<String> tags,
    required DateTime publishedAt,
    required DateTime fetchedAt,
    DateTime? processedAt,
    double? sentimentScore,
    @Default([]) List<String> relevantTickers,
  }) = _NewsItem;

  factory NewsItem.fromJson(Map<String, dynamic> json) => _$NewsItemFromJson(json);
  
  const NewsItem._();
}