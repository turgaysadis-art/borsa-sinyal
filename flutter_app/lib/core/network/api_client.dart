// ==========================================
// BORSA SİNYAL FLUTTER - API CLIENT
// ==========================================
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/prefs_service.dart';
import '../di/service_locator.dart';

class ApiClient {
  final Dio _dio;
  
  ApiClient(this._dio);
  
  // Base URL'i prefs'ten al
  void _updateBaseUrl() {
    final prefs = sl<PrefsService>();
    _dio.options.baseUrl = prefs.backendUrl;
  }
  
  // GET
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    _updateBaseUrl();
    return _dio.get(path, queryParameters: queryParameters);
  }
  
  // POST
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    _updateBaseUrl();
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }
  
  // PATCH
  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    _updateBaseUrl();
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }
  
  // DELETE
  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    _updateBaseUrl();
    return _dio.delete(path, queryParameters: queryParameters);
  }
  
  // Interceptor ekle
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}

// Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return sl<ApiClient>();
});