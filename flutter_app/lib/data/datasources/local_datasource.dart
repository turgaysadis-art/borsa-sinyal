// ==========================================
// BORSA SİNYAL FLUTTER - LOCAL DATA SOURCE
// ==========================================
import 'package:isar/isar.dart';

import '../../core/storage/isar_service.dart';
import '../models/news_source.dart';
import '../models/news_item.dart';
import '../models/signal.dart';
import '../models/app_settings.dart';

class LocalDataSource {
  final IsarService _isarService;
  final Isar _isar;
  
  LocalDataSource(this._isarService, Isar isar) : _isar = isar;
  
  // NewsSource
  Future<List<NewsSource>> getAllSources() => _isar.newsSources.where().findAll();
  
  Future<NewsSource?> getSourceById(String id) => _isar.newsSources.get(id);
  
  Future<void> saveSource(NewsSource source) => _isar.writeTxn(() => _isar.newsSources.put(source));
  
  Future<void> deleteSource(String id) => _isar.writeTxn(() => _isar.newsSources.delete(id));
  
  // NewsItem
  Future<List<NewsItem>> getLatestNews({int limit = 20, int offset = 0}) => _isar.newsItems
      .where()
      .sortByFetchedAtDesc()
      .offset(offset)
      .limit(limit)
      .findAll();
  
  Future<NewsItem?> getNewsById(String id) => _isar.newsItems.get(id);
  
  Future<List<NewsItem>> getRelatedNews({
    required String excludeId,
    required List<String> tickers,
    int limit = 10,
  }) async {
    if (tickers.isEmpty) return [];
    
    final query = _isar.newsItems.where()
      .filter()
      .idNotEqualTo(excludeId)
      .and()
      .relevantTickersElementEqualTo(tickers.first);
    
    // Diğer ticker'lar için OR sorgusu (Isar'da limited)
    return query.limit(limit).findAll();
  }
  
  Future<void> saveNewsItems(List<NewsItem> items) => _isar.writeTxn(() async {
    await _isar.newsItems.putAll(items);
  });
  
  // Signal
  Future<List<Signal>> getSignals({int limit = 30, int offset = 0}) => _isar.signals
      .where()
      .sortByDateDesc()
      .offset(offset)
      .limit(limit)
      .findAll();
  
  Future<Signal?> getLatestSignal() => _isar.signals.where().sortByDateDesc().findFirst();
  
  Future<Signal?> getSignalById(String id) => _isar.signals.get(id);
  
  Future<void> saveSignal(Signal signal) => _isar.writeTxn(() => _isar.signals.put(signal));
  
  // AppSettings
  Future<AppSettings?> getSettings() => _isar.appSettings.where().findFirst();
  
  Future<void> saveSettings(AppSettings settings) => _isar.writeTxn(() => _isar.appSettings.put(settings));
  
  // Clear
  Future<void> clearAll() => _isarService.clearAll();
}