// ==========================================
// BORSA SİNYAL FLUTTER - ISAR DATABASE SERVİSİ
// ==========================================
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/news_source.dart';
import '../../data/models/news_item.dart';
import '../../data/models/signal.dart';
import '../../data/models/app_settings.dart';

class IsarService {
  IsarService._internal();
  
  static final IsarService instance = IsarService._internal();
  
  Isar? _isar;
  bool _initialized = false;
  
  Isar get isar {
    if (_isar == null) {
      throw Exception('Isar not initialized. Call initialize() first.');
    }
    return _isar!;
  }
  
  bool get isInitialized => _initialized;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        NewsSourceSchema,
        NewsItemSchema,
        SignalSchema,
        AppSettingsSchema,
      ],
      directory: dir.path,
      inspector: true, // Isar Inspector için
    );
    
    _initialized = true;
  }
  
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      _initialized = false
    }
  }
  
  Future<void> clearAll() async {
    if (_isar != null) {
      await _isar!.writeTxn(() async {
        await _isar!.clear();
      });
    }
  }
}