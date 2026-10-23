// ==========================================
// BORSA SİNYAL FLUTTER - ROUTER
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/news/presentation/news_detail_page.dart';
import '../features/news/presentation/news_list_page.dart';
import '../features/technical/presentation/technical_detail_page.dart';
import '../features/technical/presentation/technical_overview_page.dart';
import '../features/market/presentation/market_summary_page.dart';
import '../features/signal/presentation/signal_detail_page.dart';
import '../features/signal/presentation/signal_history_page.dart';
import '../features/sources/presentation/sources_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/news',
        builder: (context, state) => const NewsListPage(),
      ),
      GoRoute(
        path: '/news/:newsId',
        builder: (context, state) => NewsDetailPage(newsId: state.pathParameters['newsId']!),
      ),
      GoRoute(
        path: '/technical',
        builder: (context, state) => const TechnicalOverviewPage(),
      ),
      GoRoute(
        path: '/technical/:symbol',
        builder: (context, state) => TechnicalDetailPage(symbol: state.pathParameters['symbol']!),
      ),
      GoRoute(
        path: '/market-summary',
        builder: (context, state) => const MarketSummaryPage(),
      ),
      GoRoute(
        path: '/signal/:signalId',
        builder: (context, state) => SignalDetailPage(signalId: state.pathParameters['signalId']!),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const SignalHistoryPage(),
      ),
      GoRoute(
        path: '/sources',
        builder: (context, state) => const SourcesPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Sayfa bulunamadı: ${state.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Ana Sayfaya Dön'),
            ),
          ],
        ),
      ),
    ),
  );
});