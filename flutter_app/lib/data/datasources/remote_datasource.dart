// ==========================================
// BORSA SİNYAL FLUTTER - REMOTE DATA SOURCE
// ==========================================
import '../models/news_source.dart';
import '../models/news_item.dart';
import '../models/signal.dart';
import '../models/technical_snapshot.dart';
import '../models/market_summary.dart';

class RemoteDataSource {
  final ApiClient _api;
  
  RemoteDataSource(this._api);
  
  // News
  Future<List<NewsItem>> getLatestNews({int limit = 20}) async {
    final response = await _api.get('/news/latest', queryParameters: {'limit': limit});
    return (response.data['items'] as List).map((e) => NewsItem.fromJson(e)).toList();
  }
  
  Future<NewsItem> getNewsById(String id) async {
    final response = await _api.get('/news/$id');
    return NewsItem.fromJson(response.data);
  }
  
  Future<List<NewsItem>> getRelatedNews({
    required String excludeId,
    required List<String> tickers,
    int limit = 10,
  }) async {
    final response = await _api.get('/news/related', queryParameters: {
      'exclude_id': excludeId,
      'tickers': tickers.join(','),
      'limit': limit,
    });
    return (response.data as List).map((e) => NewsItem.fromJson(e)).toList();
  }
  
  // Sources
  Future<List<NewsSource>> getSources({bool enabledOnly = false}) async {
    final response = await _api.get('/news/sources', queryParameters: {
      'enabled_only': enabledOnly,
    });
    return (response.data as List).map((e) => NewsSource.fromJson(e)).toList();
  }
  
  Future<NewsSource> createSource(Map<String, dynamic> data) async {
    final response = await _api.post('/news/sources', data: data);
    return NewsSource.fromJson(response.data);
  }
  
  Future<NewsSource> updateSource(String id, Map<String, dynamic> data) async {
    final response = await _api.patch('/news/sources/$id', data: data);
    return NewsSource.fromJson(response.data);
  }
  
  Future<void> deleteSource(String id) async {
    await _api.delete('/news/sources/$id');
  }
  
  Future<Map<String, dynamic>> testSource(String id) async {
    final response = await _api.post('/news/sources/$id/test');
    return response.data;
  }
  
  // Signals
  Future<List<Signal>> getSignals({int limit = 30, int offset = 0}) async {
    final response = await _api.get('/signals', queryParameters: {
      'limit': limit,
      'offset': offset,
    });
    return (response.data['signals'] as List).map((e) => Signal.fromJson(e)).toList();
  }
  
  Future<Signal> getLatestSignal() async {
    final response = await _api.get('/signals/latest');
    return Signal.fromJson(response.data);
  }
  
  Future<Signal> getSignalById(String id) async {
    final response = await _api.get('/signals/$id');
    return Signal.fromJson(response.data);
  }
  
  // Technical
  Future<Map<String, TechnicalSnapshot>> getMarketOverview() async {
    final response = await _api.get('/technical/market-overview');
    return (response.data as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, TechnicalSnapshot.fromJson(v)),
    );
  }
  
  Future<TechnicalSnapshot> getTechnicalSnapshot(String symbol) async {
    final response = await _api.get('/technical/snapshot/$symbol');
    return TechnicalSnapshot.fromJson(response.data);
  }
  
  Future<Map<String, dynamic>> getTechnicalSignals({String? symbols}) async {
    final response = await _api.get('/technical/signals', queryParameters: {
      if (symbols != null) 'symbols': symbols,
    });
    return response.data;
  }
  
  Future<Map<String, double>> getSectorPerformance() async {
    final response = await _api.get('/technical/sector-performance');
    return (response.data as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
  }
  
  // Market
  Future<MarketSummary> getMarketSummary() async {
    final response = await _api.get('/market/summary');
    return MarketSummary.fromJson(response.data);
  }
  
  Future<Map<String, dynamic>> getStockDetail(String symbol) async {
    final response = await _api.get('/market/stock/$symbol');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getMarketBreadth() async {
    final response = await _api.get('/market/breadth');
    return response.data;
  }
  
  // System
  Future<Map<String, dynamic>> getSystemStatus() async {
    final response = await _api.get('/system/status');
    return response.data;
  }
  
  Future<Map<String, dynamic>> manualFetch() async {
    final response = await _api.post('/system/fetch');
    return response.data;
  }
  
  Future<Map<String, dynamic>> manualGenerateSignal() async {
    final response = await _api.post('/system/generate-signal');
    return response.data;
  }
  
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _api.get('/system/settings');
    return response.data;
  }
}