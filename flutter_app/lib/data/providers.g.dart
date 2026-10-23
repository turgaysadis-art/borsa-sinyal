// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

final isarProvider = FutureProvider<Isar>((ref) async {
  await sl<IsarService>().initialize();
  return sl<IsarService>().isar;
});

final prefsServiceProvider = Provider<PrefsService>((ref) => sl<PrefsService>());

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(prefsServiceProvider));
});

final customThemeProvider = StateNotifierProvider<CustomThemeNotifier, CustomThemeData?>((ref) {
  return CustomThemeNotifier(ref.read(prefsServiceProvider));
});

final selectedSectorProvider = StateProvider<String>((ref) => 'Tümü');

final apiClientProvider = Provider<ApiClient>((ref) => sl<ApiClient>());

final localDataSourceProvider = Provider<LocalDataSource>((ref) {
  return sl<LocalDataSource>();
});

final remoteDataSourceProvider = Provider<RemoteDataSource>((ref) {
  return sl<RemoteDataSource>();
});

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

final signalsProvider = FutureProvider.family<List<Signal>, SignalsQuery>((ref, query) async {
  return ref.read(signalRepositoryProvider).getSignals(limit: query.limit, offset: query.offset);
});

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

final routerProvider = Provider<GoRouter>((ref) {
  throw UnimplementedError('Router not initialized');
});