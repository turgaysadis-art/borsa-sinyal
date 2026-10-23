// ==========================================
// BORSA SİNYAL FLUTTER - HOME PAGE
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils.dart';
import '../../../../shared/widgets.dart';
import '../../../../data/providers.dart';
import '../../domain/home_controller.dart';
import 'widgets/market_overview_bar.dart';
import 'widgets/market_summary_section.dart';
import 'widgets/news_carousel.dart';
import 'widgets/signal_card.dart';
import 'widgets/signal_history_tile.dart';
import 'widgets/news_list_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with WidgetsBindingObserver {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeControllerProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gittiğinde wake lock'i yenile
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(homeControllerProvider.notifier).loadMoreHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final theme = Theme.of(context);

    return AppScaffold(
      title: 'Borsa Sinyal',
      actions: [
        IconButton(
          tooltip: 'Ayarlar',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
        IconButton(
          tooltip: 'Manuel Yenile',
          icon: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_outlined),
          onPressed: state.isLoading
              ? null
              : () => ref.read(homeControllerProvider.notifier).refresh(),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.read(homeControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 1️⃣ PİYASA ÖZETİ BARI (EN ÜSTTE - Sabit)
            SliverToBoxAdapter(child: const MarketOverviewBar()),

            // 2️⃣ GENEL BİST DURUMU (Ürün Çeşitlendirme)
            SliverToBoxAdapter(child: const MarketSummarySection()),

            // 3️⃣ HABER KAYDIRICI (Mynet Tarzı Carousel)
            SliverToBoxAdapter(child: const NewsCarousel()),

            // 4️⃣ GÜNLÜK SİNYAL KARTI
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SignalCard(
                  signal: state.todaySignal,
                  onTap: () {
                    if (state.todaySignal != null) {
                      context.push('/signal/${state.todaySignal!.id}');
                    }
                  },
                ),
              ),
            ),

            // 5️⃣ SİNYAL GEÇMİŞİ
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Sinyal Geçmişi',
                onTapAll: () => context.push('/history'),
              ),
            ),
            if (state.history.isEmpty && !state.isLoadingHistory)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Henüz sinyal yok.\nYenileyerek başlayın.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: state.history.length + (state.isLoadingHistory ? 1 : 0),
                separatorBuilder: (_, __) => Divider(indent: 16, endIndent: 16, height: 1),
                itemBuilder: (_, index) {
                  if (index == state.history.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return SignalHistoryTile(
                    signal: state.history[index],
                    onTap: () => context.push('/signal/${state.history[index].id}'),
                  );
                },
              ),

            // 6️⃣ TÜM HABERLER (Liste)
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Tüm Haberler',
                onTapAll: () => context.push('/news'),
              ),
            ),
            SliverList.separated(
              itemCount: state.latestNews.length,
              separatorBuilder: (_, __) => Divider(indent: 16, endIndent: 16, height: 1),
              itemBuilder: (_, index) => NewsListTile(news: state.latestNews[index]),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}