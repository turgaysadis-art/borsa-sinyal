// ==========================================
// BORSA SİNYAL FLUTTER - TECHNICAL REPOSITORY
// ==========================================
import '../datasources/remote_datasource.dart';
import '../models/technical_snapshot.dart';

class TechnicalRepository {
  final RemoteDataSource _remote;
  
  TechnicalRepository(this._remote);
  
  Future<Map<String, TechnicalSnapshot>> getMarketOverview() async {
    return _remote.getMarketOverview();
  }
  
  Future<TechnicalSnapshot> getTechnicalSnapshot(String symbol) async {
    return _remote.getTechnicalSnapshot(symbol);
  }
  
  Future<Map<String, dynamic>> getTechnicalSignals({String? symbols}) async {
    return _remote.getTechnicalSignals(symbols: symbols);
  }
  
  Future<Map<String, double>> getSectorPerformance() async {
    return _remote.getSectorPerformance();
  }
}