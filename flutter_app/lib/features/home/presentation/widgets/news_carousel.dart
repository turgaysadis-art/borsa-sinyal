// ==========================================
// BORSA SİNYAL FLUTTER - NEWS CAROUSEL
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils.dart'
import '../../../../data/models/news_item.dart'
import '../../../../data/providers.dart'
import '../../../../shared/widgets.dart'

class NewsCarousel extends ConsumerStatefulWidget {
  const NewsCarousel({super.key});

  @override
  ConsumerState<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends ConsumerState<NewsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(latestNewsProvider(20));
    final theme = Theme.of(context);

    return newsAsync.when(
      data: (news) {
        if (news.isEmpty) return _buildEmpty(theme);
        return _buildCarousel(context, theme, news);
      },
      loading: () => _buildSkeleton(theme),
      error: (e, _) => _buildError(theme, e, ref),
    );
  }

  Widget _buildCarousel(BuildContext context, ThemeData theme, List<NewsItem> news) {
    return SizedBox(
      height: 220,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.newspaper_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'GÜNDEM HAREKETLERİ',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 24),
                      onPressed: _currentPage > 0
                          ? () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            )
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 24),
                      onPressed: _currentPage < news.length - 1
                          ? () => _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            )
                          : null,
                    ),
                    TextButton(
                      onPressed: () => context.push('/news'),
                      child: const Text('Tümü'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Carousel
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: news.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (_, index) {
                final item = news[index];
                final isCenter = index == _currentPage;
                return _NewsCarouselCard(
                  news: item,
                  isCenter: isCenter,
                  onTap: () => context.push('/news/${item.id}'),
                  onSourceTap: () => _launchSourceUrl(item.url),
                );
              },
            ),
          ),

          // Page Indicator
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                news.length.clamp(0, 7),
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) => SizedBox(
    height: 220,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 8),
          Text('Henüz haber yok', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    ),
  );

  Widget _buildSkeleton(ThemeData theme) => SizedBox(
    height: 220,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (_, __) => _CarouselCardSkeleton(theme: theme),
    ),
  );

  Widget _buildError(ThemeData theme, Object error, WidgetRef ref) => SizedBox(
    height: 220,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(height: 8),
          Text('Haberler yüklenemedi', style: theme.textTheme.bodyMedium),
          TextButton(onPressed: () => ref.refresh(latestNewsProvider(20)), child: const Text('Tekrar Dene')),
        ],
      ),
    ),
  );

  Future<void> _launchSourceUrl(String url) async {
    // url_launcher kullan
  }
}

class _NewsCarouselCard extends StatelessWidget {
  final NewsItem news;
  final bool isCenter;
  final VoidCallback onTap;
  final VoidCallback onSourceTap;

  const _NewsCarouselCard({
    required this.news,
    required this.isCenter,
    required this.onTap,
    required this.onSourceTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentimentColor = sentimentColor(news.sentimentScore ?? 0);
    final scale = isCenter ? 1.0 : 0.92;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        margin: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isCenter ? 0 : 16,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(16),
          elevation: isCenter ? 4 : 1,
          shadowColor: sentimentColor.withOpacity(0.3),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(color: sentimentColor, width: 4),
                ),
                color: theme.colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge'ler
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Badge(
                          label: _sourceShortName(news.sourceId),
                          color: theme.colorScheme.primary,
                        ),
                        _Badge(
                          label: formatRelativeTime(news.publishedAt),
                          color: theme.colorScheme.secondary,
                        ),
                        _Badge(
                          label: _categoryLabel(news.tags),
                          color: sentimentColor,
                        ),
                        _Badge(
                          label: '${(news.sentimentScore ?? 0).toStringAsFixed(2)}',
                          color: sentimentColor,
                          isSentiment: true,
                        ),
                      ],
                    ),
                  ),

                  // Başlık
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                    child: Text(
                      news.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isCenter ? 15 : 13,
                        height: 1.3,
                      ),
                    ),
                  ),

                  // Özet
                  if (news.summary != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Text(
                        news.summary!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Alt bar: Kaynağa Git + Okunma Süresi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: onSourceTap,
                          icon: const Icon(Icons.open_in_new, size: 14),
                          label: const Text('Kaynak'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${readTime(news.content ?? news.summary ?? "")} dk',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _sourceShortName(String sourceId) {
    final map = {
      'bloomberght': 'BloombergHT',
      'dunya': 'Dünya',
      'paraanaliz': 'ParaAnaliz',
      'investingtr': 'InvestingTR',
      'mynet_finans': 'Mynet Finans',
      'mynet_borsa': 'Mynet Borsa',
      'kap': 'KAP',
      'youtube': 'YouTube',
    };
    return map[sourceId.toLowerCase()] ?? sourceId;
  }

  String _categoryLabel(List<String> tags) {
    if (tags.isEmpty) return 'Genel';
    final priority = ['kap_bildirim', 'ekonomik', 'politik_ic', 'geopolitik_savas', 'kuresel_denge', 'sektor_ozel', 'sirket_ozel'];
    for (final p in priority) {
      if (tags.contains(p)) return p.replaceAll('_', ' ').toUpperCase();
    }
    return tags.first.toUpperCase();
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSentiment;

  const _Badge({
    required this.label,
    required this.color,
    this.isSentiment = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isSentiment ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _CarouselCardSkeleton extends StatelessWidget {
  final ThemeData theme;

  const _CarouselCardSkeleton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Card(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(3, (i) => _ShimmerBox(width: 60, height: 16, theme: theme)),
              ),
              const SizedBox(height: 10),
              _ShimmerBox(width: double.infinity, height: 20, theme: theme),
              const SizedBox(height: 6),
              _ShimmerBox(width: double.infinity, height: 14, theme: theme),
              const SizedBox(height: 6),
              _ShimmerBox(width: 150, height: 14, theme: theme),
              const Spacer(),
              _ShimmerBox(width: double.infinity, height: 32, theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final ThemeData theme;

  const _ShimmerBox({required this.width, required this.height, required this.theme});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + _c.value * 2, 0),
          end: Alignment(1.0 + _c.value * 2, 0),
          colors: [
            widget.theme.colorScheme.surfaceContainerHighest,
            widget.theme.colorScheme.surfaceContainer,
            widget.theme.colorScheme.surfaceContainerHighest,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    ),
  );
}