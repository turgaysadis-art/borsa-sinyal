// ==========================================
// BORSA SİNYAL FLUTTER - DEPENDENCY INJECTION
// ==========================================
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/isar_service.dart';
import '../storage/prefs_service.dart';
import '../network/api_client.dart';
import '../data/datasources/local_datasource.dart';
import '../data/datasources/remote_datasource.dart';
import '../data/repositories/source_repository.dart';
import '../data/repositories/news_repository.dart'
import '../data/repositories/signal_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/market_repository.dart';
import '../data/repositories/technical_repository.dart';

final sl = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Core
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<PrefsService>(() => PrefsService(sl()));
  
  // Isar
  sl.registerLazySingleton<IsarService>(() => IsarService.instance);
  
  // Network
  sl.registerLazySingleton<Dio>(() {
    final dio = Dio(BaseOptions(
      baseUrl: 'http://10.0.2.2:8000/api/v1', // Android emulator localhost
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));
    return dio;
  });
  sl.registerLazySingleton<ApiClient>(() => ApiClient(sl()));
  
  // Data Sources
  sl.registerLazySingleton<LocalDataSource>(() => LocalDataSource(sl(), sl()));
  sl.registerLazySingleton<RemoteDataSource>(() => RemoteDataSource(sl()));
  
  // Repositories
  sl.registerLazySingleton<SourceRepository>(() => SourceRepository(sl(), sl()));
  sl.registerLazySingleton<NewsRepository>(() => NewsRepository(sl(), sl()));
  sl.registerLazySingleton<SignalRepository>(() => SignalRepository(sl(), sl()));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepository(sl()));
  sl.registerLazySingleton<MarketRepository>(() => MarketRepository(sl(), sl()));
  sl.registerLazySingleton<TechnicalRepository>(() => TechnicalRepository(sl(), sl()));
}