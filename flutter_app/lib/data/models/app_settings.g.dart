// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) {
  return AppSettings(
    id: json['id'] as String? ?? 'settings',
    themeMode: json['themeMode'] as String? ?? 'system',
    customSeedColor: json['customSeedColor'] as int? ?? 0xFF006B3C,
    customBackgroundLight: json['customBackgroundLight'] as int? ?? 0xFFF8F9FA,
    customBackgroundDark: json['customBackgroundDark'] as int? ?? 0xFF0A0A0A,
    customSurfaceLight: json['customSurfaceLight'] as int? ?? 0xFFFFFFFF,
    customSurfaceDark: json['customSurfaceDark'] as int? ?? 0xFF1E1E1E,
    refreshIntervalMinutes: json['refreshIntervalMinutes'] as int? ?? 30,
    autoRefreshEnabled: json['autoRefreshEnabled'] as bool? ?? true,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    signalThreshold: (json['signalThreshold'] as num?)?.toDouble() ?? 0.55,
    language: json['language'] as String? ?? 'tr',
    backendUrl: json['backendUrl'] as String? ?? 'http://10.0.2.2:8000/api/v1',
  );
}

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) {
  return {
    'id': instance.id,
    'themeMode': instance.themeMode,
    'customSeedColor': instance.customSeedColor,
    'customBackgroundLight': instance.customBackgroundLight,
    'customBackgroundDark': instance.customBackgroundDark,
    'customSurfaceLight': instance.customSurfaceLight,
    'customSurfaceDark': instance.customSurfaceDark,
    'refreshIntervalMinutes': instance.refreshIntervalMinutes,
    'autoRefreshEnabled': instance.autoRefreshEnabled,
    'notificationsEnabled': instance.notificationsEnabled,
    'signalThreshold': instance.signalThreshold,
    'language': instance.language,
    'backendUrl': instance.backendUrl,
  };
}