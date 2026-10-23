// ==========================================
// BORSA SİNYAL FLUTTER - SIGNAL REPOSITORY
// ==========================================
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';
import '../models/signal.dart';

class SignalRepository {
  final LocalDataSource _local;
  final RemoteDataSource _remote;
  
  SignalRepository(this._local, this._remote);
  
  Future<List<Signal>> getSignals({int limit = 30, int offset = 0}) async {
    try {
      final remote = await _remote.getSignals(limit: limit, offset: offset);
      for (final signal in remote) {
        await _local.saveSignal(signal);
      }
      return remote;
    } catch (e) {
      return _local.getSignals(limit: limit, offset: offset);
    }
  }
  
  Future<Signal?> getLatestSignal() async {
    try {
      final remote = await _remote.getLatestSignal();
      await _local.saveSignal(remote);
      return remote;
    } catch (e) {
      return _local.getLatestSignal();
    }
  }
  
  Future<Signal> getSignalById(String id) async {
    try {
      final remote = await _remote.getSignalById(id);
      await _local.saveSignal(remote);
      return remote;
    } catch (e) {
      final local = await _local.getSignalById(id);
      if (local != null) return local;
      rethrow;
    }
  }
  
  Future<void> syncSignals() async {
    try {
      final remote = await _remote.getSignals(limit: 100);
      for (final signal in remote) {
        await _local.saveSignal(signal);
      }
    } catch (e) {
      // Offline
    }
  }
}