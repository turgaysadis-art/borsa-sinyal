// ==========================================
// BORSA SİNYAL FLUTTER - TEMA SİSTEMİ
// ==========================================
import 'package:flutter/material.dart';

class AppTheme {
  // Göz yormayan borsa yeşili
  static const Color _customSeed = Color(0xFF006B3C);
  static const Color _customSeedLight = Color(0xFF2E7D32);
  static const Color _customSeedDark = Color(0xFF4CAF50);

  // --- LIGHT ---
  static ThemeData light({Color seed = _customSeed}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
          surface: const Color(0xFFF8F9FA),
          surfaceContainerHighest: const Color(0xFFE8F5E9),
          primary: seed,
          onPrimary: Colors.white,
          secondary: const Color(0xFF1976D2),
          onSecondary: Colors.white,
          error: const Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1A1A1A),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.green.withOpacity(0.1),
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return seed.withOpacity(0.2);
              }
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return seed;
              }
              return Colors.grey.shade700;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(color: seed, width: 1.5);
              }
              return BorderSide(color: Colors.grey.shade300, width: 1);
            }),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: seed.withOpacity(0.15),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: seed, size: 24);
            }
            return IconThemeData(color: Colors.grey.shade600, size: 24);
          }),
        ),
      );

  // --- DARK ---
  static ThemeData dark({Color seed = _customSeedDark}) => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          surfaceContainerHighest: const Color(0xFF1E1E1E),
          surfaceContainer: const Color(0xFF1A1A1A),
          primary: seed,
          onPrimary: Colors.white,
          secondary: const Color(0xFF64B5F6),
          onSecondary: Colors.black,
          error: const Color(0xFFEF5350),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: const Color(0xFF1E1E1E),
          surfaceTintColor: Colors.transparent,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFFFFFFFF),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.green.withOpacity(0.15),
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          backgroundColor: const Color(0xFF2A2A2A),
          selectedColor: seed.withOpacity(0.3),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return seed.withOpacity(0.3);
              }
              return const Color(0xFF2A2A2A);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return seed;
              }
              return Colors.grey.shade400;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return BorderSide(color: seed, width: 1.5);
              }
              return BorderSide(color: Colors.grey.shade700, width: 1);
            }),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF121212),
          indicatorColor: seed.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: seed, size: 24);
            }
            return IconThemeData(color: Colors.grey.shade500, size: 24);
          }),
        ),
      );

  // --- CUSTOM (Kullanıcı kendi rengini seçer) ---
  static ThemeData custom({
    required Brightness brightness,
    required Color seedColor,
    required Color backgroundColor,
    required Color surfaceColor,
  }) =>
      (brightness == Brightness.light ? light(seed: seedColor) : dark(seed: seedColor))
          .copyWith(
            scaffoldBackgroundColor: backgroundColor,
            cardTheme: CardThemeData(
              color: surfaceColor,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              surfaceTintColor: Colors.transparent,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: brightness == Brightness.light ? const Color(0xFF1A1A1A) : Colors.white,
            ),
          );
}