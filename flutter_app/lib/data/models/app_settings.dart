// ==========================================
// BORSA SİNYAL FLUTTER - APP SETTINGS MODEL
// ==========================================
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';
import 'package:flutter/material.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
@Collection()
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('settings') @Id() String id,
    @Default('system') String themeMode, // 'light', 'dark', 'custom', 'system'
    // Custom theme
    @Default(0xFF006B3C) int customSeedColor,
    @Default(0xFFF8F9FA) int customBackgroundLight,
    @Default(0xFF0A0A0A) int customBackgroundDark,
    @Default(0xFFFFFFFF) int customSurfaceLight,
    @Default(0xFF1E1E1E) int customSurfaceDark,
    @Default(30) int refreshIntervalMinutes,
    @Default(true) bool autoRefreshEnabled,
    @Default(true) bool notificationsEnabled,
    @Default(0.55) double signalThreshold,
    @Default('tr') String language,
    @Default('http://10.0.2.2:8000/api/v1') String backendUrl,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
  
  const AppSettings._();
  
  // Helper getters
  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      case 'custom': return ThemeMode.system; // Custom temada sistem temalı kullanılır
      default: return ThemeMode.system;
    }
  }
  
  Color get seedColor => Color(customSeedColor);
  Color get backgroundLight => Color(customBackgroundLight);
  Color get backgroundDark => Color(customBackgroundDark);
  Color get surfaceLight => Color(customSurfaceLight);
  Color get surfaceDark => Color(customSurfaceDark);
}