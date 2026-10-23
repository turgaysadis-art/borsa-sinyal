// ==========================================
// BORSA SİNYAL FLUTTER - MARKET REPOSITORY
// ==========================================
import '../datasources/remote_datasource.dart';
import '../models/market_summary.dart';

class MarketRepository {
  final RemoteDataSource _remote;
  
  MarketRepository(this._remote);
  
  Future<MarketSummary> getMarketSummary() async {
    return _remote.getMarketSummary();
  }
  
  Future<Map<String, dynamic>> getStockDetail(String symbol) async {
    return _remote.getStockDetail(symbol);
  }
  
  Future<Map<String, dynamic>> getMarketBreadth() async {
    return _remote.getMarketBreadth();
  }
}