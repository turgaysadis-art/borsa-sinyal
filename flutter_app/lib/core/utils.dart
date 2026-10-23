// ==========================================
// BORSA SİNYAL FLUTTER - UTILITIES
// ==========================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  double get screenWidth => mediaQuery.size.width;
  double get screenHeight => mediaQuery.size.height;
  double get statusBarHeight => mediaQuery.padding.top;
  double get bottomPadding => mediaQuery.padding.bottom;
}

String formatTurkishDate(DateTime date, {bool showTime = true}) {
  final formatter = DateFormat(showTime ? 'd MMMM yyyy HH:mm' : 'd MMMM yyyy', 'tr_TR');
  return formatter.format(date.toLocal());
}

String formatRelativeTime(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date.toLocal());
  
  if (diff.inMinutes < 1) return 'Az önce';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
  if (diff.inHours < 24) return '${diff.inHours} sa önce';
  if (diff.inDays < 7) return '${diff.inDays} gün önce';
  return formatTurkishDate(date, showTime: false);
}

String formatPrice(double price) {
  if (price >= 10000) return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[0]},');
  if (price >= 100) return price.toStringAsFixed(1);
  if (price >= 1) return price.toStringAsFixed(2);
  return price.toStringAsFixed(4);
}

String formatChange(double change, double changePct) {
  final sign = change >= 0 ? '▲' : '▼';
  return '$sign ${change.abs().toStringAsFixed(2)} (${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%)';
}

Color sentimentColor(double score) {
  if (score > 0.1) return const Color(0xFF2E7D32);
  if (score < -0.1) return const Color(0xFFD32F2F);
  return const Color(0xFFED6C02);
}

Color rsiColor(double rsi) {
  if (rsi >= 70) return Colors.red;
  if (rsi <= 30) return Colors.green;
  return Colors.orange;
}

int readTime(String text) {
  final words = text.split(RegExp(r'\s+')).length;
  return (words / 200).ceil().clamp(1, 30);
}