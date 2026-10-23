// ==========================================
// BORSA SİNYAL FLUTTER - SOURCE REPOSITORY
// ==========================================
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';
import '../models/news_source.dart';

class SourceRepository {
  final LocalDataSource _local;
  final RemoteDataSource _remote;
  
  SourceRepository(this._local, this._remote);
  
  Future<List<NewsSource>> getAllSources({bool enabledOnly = false}) async {
    try {
      final remote = await _remote.getSources(enabledOnly: enabledOnly);
      // Local'e kaydet
      for (final source in remote) {
        await _local.saveSource(source);
      }
      return remote;
    } catch (e) {
      // Offline: local'den getir
      final local = await _local.getAllSources();
      if (enabledOnly) {
        return local.where((s) => s.enabled).toList();
      }
      return local;
    }
  }
  
  Future<NewsSource?> getSourceById(String id) async {
    try {
      return await _remote.getSourceById(id);
    } catch (e) {
      return await _local.getSourceById(id);
    }
  }
  
  Future<NewsSource> createSource(NewsSource source) async {
    final created = await _remote.createSource(source.toJson());
    await _local.saveSource(created);
    return created;
  }
  
  Future<NewsSource> updateSource(NewsSource source) async {
    final updated = await _remote.updateSource(source.id, source.toJson());
    await _local.saveSource(updated);
    return updated;
  }
  
  Future<void> deleteSource(String id) async {
    await _remote.deleteSource(id);
    await _local.deleteSource(id);
  }
  
  Future<void> toggleSource(String id) async {
    final source = await getSourceById(id);
    if (source != null) {
      await updateSource(source.copyWith(enabled: !source.enabled));
    }
  }
  
  Future<Map<String, dynamic>> testSource(String id) async {
    return _remote.testSource(id);
  }
}