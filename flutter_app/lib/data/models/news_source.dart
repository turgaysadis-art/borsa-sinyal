// ==========================================
// BORSA SİNYAL FLUTTER - NEWS SOURCE MODEL
// ==========================================
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'news_source.freezed.dart';
part 'news_source.g.dart';

@freezed
@Collection()
class NewsSource with _$NewsSource {
  const factory NewsSource({
    @Default('') @Id() String id,
    required String name,
    required String type, // 'rss', 'youtube', 'kap', 'custom'
    required String url,
    @Default(true) bool enabled,
    @Default(0.8) double weight,
    @Default({}) Map<String, dynamic> config,
    @Default([]) List<String> tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastFetchedAt,
    String? lastError,
  }) = _NewsSource;

  factory NewsSource.fromJson(Map<String, dynamic> json) => _$NewsSourceFromJson(json);
  
  // Isar için
  const NewsSource._();
}