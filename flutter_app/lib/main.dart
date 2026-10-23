// ==========================================
// BORSA SİNYAL FLUTTER - ANA GİRİŞ NOKTASI
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'core/theme/app_theme.dart';
import 'core/di/service_locator.dart';
import 'core/storage/isar_service.dart';
import 'app/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Wake Lock - Ekran açık kalsın
  await WakelockPlus.enable();
  
  // Dependency Injection
  await setupServiceLocator();
  
  // Isar DB başlat
  await IsarService.instance.initialize();
  
  runApp(const ProviderScope(child: BorsaSinyalApp()));
}

class BorsaSinyalApp extends ConsumerWidget {
  const BorsaSinyalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final customTheme = ref.watch(customThemeProvider);
    
    ThemeData lightTheme, darkTheme;
    
    if (customTheme != null) {
      lightTheme = AppTheme.custom(
        brightness: Brightness.light,
        seedColor: customTheme.seedColor,
        backgroundColor: customTheme.backgroundLight,
        surfaceColor: customTheme.surfaceLight,
      );
      darkTheme = AppTheme.custom(
        brightness: Brightness.dark,
        seedColor: customTheme.seedColor,
        backgroundColor: customTheme.backgroundDark,
        surfaceColor: customTheme.surfaceDark,
      );
    } else {
      lightTheme = AppTheme.light();
      darkTheme = AppTheme.dark();
    }
    
    return MaterialApp.router(
      title: 'Borsa Sinyal',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
    );
  }
}