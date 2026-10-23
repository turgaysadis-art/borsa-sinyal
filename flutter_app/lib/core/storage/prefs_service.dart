// ==========================================
// BORSA SİNYAL FLUTTER - SHARED PREFERENCES SERVİSİ
// ==========================================
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PrefsService {
  final SharedPreferences _prefs;
  
  PrefsService(this._prefs);
  
  // Keys
  static const _themeMode = 'theme_mode';
  static const _customSeedColor = 'custom_seed_color';
  static const _customBgLight = 'custom_bg_light';
  static const _customBgDark = 'custom_bg_dark';
  static const _customSurfaceLight = 'custom_surface_light';
  static const _customSurfaceDark = 'custom_surface_dark';
  static const _refreshInterval = 'refresh_interval_minutes';
  static const _autoRefresh = 'auto_refresh_enabled';
  static const _notifications = 'notification_enabled';
  static const _signalThreshold = 'signal_threshold';
  static const _language = 'language';
  static const _backendUrl = 'backend_url';
  
  // Theme
  String get themeMode => _prefs.getString(_themeMode) ?? 'system';
  Future<void> setThemeMode(String value) => _prefs.setString(_themeMode, value);
  
  Color? get customSeedColor {
    final val = _prefs.getInt(_customSeedColor);
    return val != null ? Color(val) : null;
  }
  Future<void> setCustomSeedColor(Color color) => _prefs.setInt(_customSeedColor, color.value);
  
  Color? get customBgLight {
    final val = _prefs.getInt(_customBgLight);
    return val != null ? Color(val) : null;
  }
  Future<void> setCustomBgLight(Color color) => _prefs.setInt(_customBgLight, color.value);
  
  Color? get customBgDark {
    final val = _prefs.getInt(_customBgDark);
    return val != null ? Color(val) : null;
  }
  Future<void> setCustomBgDark(Color color) => _prefs.setInt(_customBgDark, color.value);
  
  Color? get customSurfaceLight {
    final val = _prefs.getInt(_customSurfaceLight);
    return val != null ? Color(val) : null;
  }
  Future<void> setCustomSurfaceLight(Color color) => _prefs.setInt(_customSurfaceLight, color.value);
  
  Color? get customSurfaceDark {
    final val = _prefs.getInt(_customSurfaceDark);
    return val != null ? Color(val) : null;
  }
  Future<void> setCustomSurfaceDark(Color color) => _prefs.setInt(_customSurfaceDark, color.value);
  
  // Settings
  int get refreshIntervalMinutes => _prefs.getInt(_refreshInterval) ?? 30;
  Future<void> setRefreshIntervalMinutes(int value) => _prefs.setInt(_refreshInterval, value);
  
  bool get autoRefreshEnabled => _prefs.getBool(_autoRefresh) ?? true;
  Future<void> setAutoRefreshEnabled(bool value) => _prefs.setBool(_autoRefresh, value);
  
  bool get notificationsEnabled => _prefs.getBool(_notifications) ?? true;
  Future<void> setNotificationsEnabled(bool value) => _prefs.setBool(_notifications, value);
  
  double get signalThreshold => _prefs.getDouble(_signalThreshold) ?? 0.55;
  Future<void> setSignalThreshold(double value) => _prefs.setDouble(_signalThreshold, value);
  
  String get language => _prefs.getString(_language) ?? 'tr';
  Future<void> setLanguage(String value) => _prefs.setString(_language, value);
  
  String get backendUrl => _prefs.getString(_backendUrl) ?? 'http://10.0.2.2:8000/api/v1';
  Future<void> setBackendUrl(String value) => _prefs.setString(_backendUrl, value);
  
  // Clear all
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}