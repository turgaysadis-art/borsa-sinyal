// ==========================================
// BORSA SİNYAL FLUTTER - NEWS REPOSITORY
// ==========================================
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';
import '../models/news_item.dart';

class NewsRepository {
  final LocalDataSource _local;
  final RemoteDataSource _remote;
  
  NewsRepository(this._local, this._remote);
  
  Future<List<NewsItem>> getLatestNews({int limit = 20, int offset = 0}) async {
    try {
      final remote = await _remote.getLatestNews(limit: limit);
      // Local'e kaydet (background)
      _local.saveNewsItems(remote);
      return remote;
    } catch (e) {
      return _local.getLatestNews(limit: limit, offset: offset);
    }
  }
  
  Future<NewsItem> getNewsById(String id) async {
    try {
      final remote = await _remote.getNewsById(id);
      await _local.saveNewsItems([remote]);
      return remote;
    } catch (e) {
      final local = await _local.getNewsById(id);
      if (local != null) return local;
      rethrow;
    }
  }
  
  Future<List<NewsItem>> getRelatedNews({
    required String excludeId,
    required List<String> tickers,
    int limit = 10,
  }) async {
    try {
      final remote = await _remote.getRelatedNews(
        excludeId: excludeId,
        tickers: tickers,
        limit: limit,
      );
      return remote;
    } catch (e) {
      return _local.getRelatedNews(
        excludeId: excludeId,
        tickers: tickers,
        limit: limit,
      );
    }
  }
  
  Future<void> syncNews() async {
    try {
      final remote = await _remote.getLatestNews(limit: 100);
      await _local.saveNewsItems(remote);
    } catch (e) {
      // Offline
    }
  }
}