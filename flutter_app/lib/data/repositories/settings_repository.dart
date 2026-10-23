// ==========================================
// BORSA SİNYAL FLUTTER - SETTINGS REPOSITORY
// ==========================================
import '../datasources/local_datasource.dart';
import '../datasources/remote_datasource.dart';
import '../models/app_settings.dart';

class SettingsRepository {
  final LocalDataSource _local;
  final RemoteDataSource _remote;
  
  SettingsRepository(this._local, this._remote);
  
  Future<AppSettings> getSettings() async {
    try {
      final remote = await _remote.getSettings();
      // Remote'den ayarları güncelle (varsa)
      return AppSettings.fromJson(remote);
    } catch (e) {
      final local = await _local.getSettings();
      return local ?? AppSettings(id: 'settings');
    }
  }
  
  Future<void> saveSettings(AppSettings settings) async {
    await _local.saveSettings(settings);
  }
  
  Future<void> updateThemeMode(String mode) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(themeMode: mode));
  }
  
  Future<void> updateCustomTheme({
    Color? seedColor,
    Color? backgroundLight,
    Color? backgroundDark,
    Color? surfaceLight,
    Color? surfaceDark,
  }) async {
    final settings = await getSettings();
    await saveSettings(settings.copyWith(
      customSeedColor: seedColor?.value ?? settings.customSeedColor,
      customBackgroundLight: backgroundLight?.value ?? settings.customBackgroundLight,
      customBackgroundDark: backgroundDark?.value ?? settings.customBackgroundDark,
      customSurfaceLight: surfaceLight?.value ?? settings.customSurfaceLight,
      customSurfaceDark: surfaceDark?.value ?? settings.customSurfaceDark,
    ));
  }
}