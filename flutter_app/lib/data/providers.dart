// ==========================================
// BORSA SİNYAL FLUTTER - PROVIDERS
// ==========================================
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../core/di/service_locator.dart';
import '../core/storage/isar_service.dart';
import '../core/storage/prefs_service.dart';
import '../core/network/api_client.dart';
import '../data/datasources/local_datasource.dart';
import '../data/datasources/remote_datasource.dart';
import '../data/repositories/source_repository.dart';
import '../data/repositories/news_repository.dart';
import '../data/repositories/signal_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/market_repository.dart';
import '../data/repositories/technical_repository.dart';
import '../data/models/app_settings.dart';

// Core
final isarProvider = FutureProvider<Isar>((ref) async {
  await sl<IsarService>().initialize();
  return sl<IsarService>().isar;
});

final prefsServiceProvider = Provider<PrefsService>((ref) => sl<PrefsService>());

// Settings from prefs
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(prefsServiceProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final PrefsService _prefs;
  
  ThemeModeNotifier(this._prefs) : super(_parseThemeMode(_prefs.themeMode));
  
  static ThemeMode _parseThemeMode(String mode) {
    switch (mode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      case 'custom': return ThemeMode.system;
      default: return ThemeMode.system;
    }
  }
  
  Future<void> setThemeMode(String mode) async {
    await _prefs.setThemeMode(mode);
    state = _parseThemeMode(mode);
  }
}

// Custom theme
final customThemeProvider = StateNotifierProvider<CustomThemeNotifier, CustomThemeData?>((ref) {
  return CustomThemeNotifier(ref.read(prefsServiceProvider));
});

class CustomThemeNotifier extends StateNotifier<CustomThemeData?> {
  final PrefsService _prefs;
  
  CustomThemeNotifier(this._prefs) : super(_loadFromPrefs(_prefs));
  
  static CustomThemeData? _loadFromPrefs(PrefsService prefs) {
    final seed = prefs.customSeedColor;
    final bgLight = prefs.customBgLight;
    final bgDark = prefs.customBgDark;
    final surfaceLight = prefs.customSurfaceLight;
    final surfaceDark = prefs.customSurfaceDark;
    
    if (seed == null || bgLight == null || bgDark == null || surfaceLight == null || surfaceDark == null) {
      return null;
    }
    
    return CustomThemeData(
      seedColor: seed,
      backgroundLight: bgLight,
      backgroundDark: bgDark,
      surfaceLight: surfaceLight,
      surfaceDark: surfaceDark,
    );
  }
  
  Future<void> updateTheme({
    Color? seedColor,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? surfaceLight,
    Color? surfaceDark,
  }) async {
    final current = state ?? CustomThemeData(
      seedColor: const Color(0xFF006B3C),
      backgroundLight: const Color(0xFFF8F9FA),
      backgroundDark: const Color(0xFF0A0A0A),
      surfaceLight: Colors.white,
      surfaceDark: const Color(0xFF1E1E1E),
    );
    
    final updated = current.copyWith(
      seedColor: seedColor,
      backgroundLight: backgroundLight,
      backgroundDark: backgroundDark,
      surfaceLight: surfaceLight,
      surfaceDark: surfaceDark,
    );
    
    state = updated;
    
    // Prefs'e kaydet
    if (seedColor != null) await _prefs.setCustomSeedColor(seedColor);
    if (backgroundLight != null) await _prefs.setCustomBgLight(backgroundLight);
    if (backgroundDark != null) await _prefs.setCustomBgDark(backgroundDark);
    if (surfaceLight != null) await _prefs.setCustomSurfaceLight(surfaceLight);
    if (surfaceDark != null) await _prefs.setCustomSurfaceDark(surfaceDark);
  }
  
  Future<void> clear() async {
    state = null;
    // Prefs'ten de temizle (opsiyonel)
  }
}

class CustomThemeData {
  final Color seedColor;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color surfaceLight;
  final Color surfaceDark;
  
  CustomThemeData({
    required this.seedColor,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.surfaceLight,
    required this.surfaceDark,
  });
  
  CustomThemeData copyWith({
    Color? seedColor,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? surfaceLight,
    Color? surfaceDark,
  }) {
    return CustomThemeData(
      seedColor: seedColor ?? this.seedColor,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceDark: surfaceDark ?? this.surfaceDark,
    );
  }
}

// Selected sector for market summary
final selectedSectorProvider = StateProvider<String>((ref) => 'Tümü');

// Network
final apiClientProvider = Provider<ApiClient>((ref) => sl<ApiClient>());

// Data Sources
final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return sl<LocalDataSource>();
});

final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  return sl<RemoteDataSource>();
});

// Repositories
final sourceRepositoryProvider = Provider<SourceRepository>((ref) {
  return sl<SourceRepository>();
});

final newsRepositoryProvider = Provider<NewsRepository>((ref) {
  return sl<NewsRepository>();
});

final signalRepositoryProvider = Provider<SignalRepository>((ref) {
  return sl<SignalRepository>();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return sl<SettingsRepository>();
});

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return sl<MarketRepository>();
});

final technicalRepositoryProvider = Provider<TechnicalRepository>((ref) {
  return sl<TechnicalRepository>();
});

// Data Providers
final latestNewsProvider = FutureProvider.family<List<NewsItem>, int>((ref, limit) async {
  return ref.read(newsRepositoryProvider).getLatestNews(limit: limit);
});

final newsDetailProvider = FutureProvider.family<NewsItem, String>((ref, newsId) async {
  return ref.read(newsRepositoryProvider).getNewsById(newsId);
});

final relatedNewsProvider = FutureProvider.family<List<NewsItem>, RelatedNewsQuery>((ref, query) async {
  return ref.read(newsRepositoryProvider).getRelatedNews(
    excludeId: query.excludeId,
    tickers: query.tickers,
    limit: 10,
  );
});

@freezed
class RelatedNewsQuery with _$RelatedNewsQuery {
  const factory RelatedNewsQuery({
    required String excludeId,
    required List<String> tickers,
  }) = _RelatedNewsQuery;
}

final signalsProvider = FutureProvider.family<List<Signal>, SignalsQuery>((ref, query) async {
  return ref.read(signalRepositoryProvider).getSignals(limit: query.limit, offset: query.offset);
});

@freezed
class SignalsQuery with _$SignalsQuery {
  const factory SignalsQuery({
    @Default(30) int limit,
    @Default(0) int offset,
  }) = _SignalsQuery;
}

final latestSignalProvider = FutureProvider<Signal?>((ref) async {
  return ref.read(signalRepositoryProvider).getLatestSignal();
});

final signalDetailProvider = FutureProvider.family<Signal, String>((ref, signalId) async {
  return ref.read(signalRepositoryProvider).getSignalById(signalId);
});

final marketSummaryProvider = FutureProvider<MarketSummary>((ref) async {
  return ref.read(marketRepositoryProvider).getMarketSummary();
});

final technicalSnapshotsProvider = FutureProvider<Map<String, TechnicalSnapshot>>((ref) async {
  return ref.read(technicalRepositoryProvider).getMarketOverview();
});

final technicalDetailProvider = FutureProvider.family<TechnicalSnapshot, String>((ref, symbol) async {
  return ref.read(technicalRepositoryProvider).getTechnicalSnapshot(symbol);
});

final technicalSignalsProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, symbols) async {
  return ref.read(technicalRepositoryProvider).getTechnicalSignals(symbols: symbols);
});

final sectorPerformanceProvider = FutureProvider<Map<String, double>>((ref) async {
  return ref.read(technicalRepositoryProvider).getSectorPerformance();
});

// Router
final routerProvider = Provider<GoRouter>((ref) {
  // Router will be created in router.dart
  throw UnimplementedError('Router not initialized');
});