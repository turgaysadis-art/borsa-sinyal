// ==========================================
// BORSA SİNYAL FLUTTER - NEWS DETAIL PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:go_router/go_router.dart'
import 'package:url_launcher/url_launcher.dart'
import 'package:webview_flutter/webview_flutter.dart'
import 'package:share_plus/share_plus.dart'

import '../../../../core/theme/app_theme.dart'
import '../../../../core/utils.dart'
import '../../../../data/models/news_item.dart'
import '../../../../data/providers.dart'
import '../../../../shared/widgets.dart'

class NewsDetailPage extends ConsumerStatefulWidget {
  final String newsId

  const NewsDetailPage({super.key, required this.newsId})

  @override
  ConsumerState<NewsDetailPage> createState() => _NewsDetailPageState()
}

class _NewsDetailPageState extends ConsumerState<NewsDetailPage> {
  late final WebViewController _webController
  bool _webViewReady = false

  @override
  void initState() {
    super.initState()
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _webViewReady = true),
      ))
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsDetailProvider(widget.newsId))

    return newsAsync.when(
      data: (news) => _buildDetail(context, news),
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, e),
    )
  }

  Widget _buildDetail(BuildContext context, NewsItem news) {
    final theme = Theme.of(context)
    final sentimentColor = sentimentColor(news.sentimentScore ?? 0)

    return AppScaffold(
      title: '',
      actions: [
        IconButton(
          tooltip: 'Kaynağa Git',
          icon: const Icon(Icons.open_in_new),
          onPressed: () => _launchUrl(news.url),
        ),
        IconButton(
          tooltip: 'Paylaş',
          icon: const Icon(Icons.share_outlined),
          onPressed: () => _shareNews(news),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      sentimentColor.withOpacity(0.15),
                      sentimentColor.withOpacity(0.02),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(color: sentimentColor.withOpacity(0.3)),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip(label: _sourceName(news.sourceId), color: theme.colorScheme.primary),
                        _Chip(label: formatRelativeTime(news.publishedAt), color: theme.colorScheme.secondary),
                        _Chip(label: _categoryLabel(news.tags), color: sentimentColor),
                        _Chip(label: '${(news.sentimentScore ?? 0).toStringAsFixed(2)}', color: sentimentColor, isSentiment: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      news.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Content
                  if (news.content != null && news.content!.isNotEmpty) ...[
                    _ContentSection(content: news.content!),
                  ] else if (news.summary != null) ...[
                    _ContentSection(content: news.summary!),
                  ],

                  const SizedBox(height: 24),

                  // Etkilenen Semboller
                  if (news.relevantTickers.isNotEmpty) ...[
                    _SectionTitle(title: '📊 Etkilenen Semboller'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: news.relevantTickers.map((t) => _TickerChip(symbol: t)).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Teknik Analiz (varsa)
                  if (news.relevantTickers.isNotEmpty) ...[
                    _SectionTitle(title: '📈 Teknik Etki Analizi'),
                    const SizedBox(height: 8),
                    _TechnicalImpactTickers(tickers: news.relevantTickers),
                    const SizedBox(height: 24),
                  ],

                  // İlgili Haberler
                  _RelatedNewsSection(newsId: news.id, tickers: news.relevantTickers),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    )
  }

  Widget _ContentSection({required String content}) {
    final theme = Theme.of(context)
    return SelectableText(
      content,
      style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
    )
  }

  Widget _SectionTitle({required String title}) {
    final theme = Theme.of(context)
    return Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))
  }

  Widget _TickerChip({required String symbol}) {
    final theme = Theme.of(context)
    return ActionChip(
      label: Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () => context.push('/technical/$symbol'),
      backgroundColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
    )
  }

  Widget _TechnicalImpactTickers({required List<String> tickers}) {
    return Column(
      children: tickers.take(3).map((symbol) => _TechnicalMiniCard(symbol: symbol)).toList(),
    )
  }

  Widget _TechnicalMiniCard({required String symbol}) {
    return Consumer(
      builder: (context, ref, _) {
        final techAsync = ref.watch(technicalDetailProvider(symbol))
        return techAsync.when(
          data: (tech) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: tech.trendLong == 'UP' ? Colors.green : Colors.red,
                child: Text(symbol.replaceAll('.IS', '').substring(0, 1), style: const TextStyle(color: Colors.white)),
              ),
              title: Text('$symbol • ${tech.summary}'),
              subtitle: Text('EMA200: ${tech.distEma200Pct >= 0 ? "+" : ""}${tech.distEma200Pct.toStringAsFixed(1)}% | RSI: ${tech.rsi14.toStringAsFixed(0)} | ${_trendTr(tech.trendLong)}'),
              onTap: () => context.push('/technical/$symbol'),
            ),
          ),
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        )
      },
    )
  }

  String _trendTr(String trend) {
    switch (trend) {
      case 'UP': return 'Yükseliş'
      case 'DOWN': return 'Düşüş'
      default: return 'Yatay'
    }
  }

  Widget _RelatedNewsSection({required String newsId, required List<String> tickers}) {
    return Consumer(
      builder: (context, ref, _) {
        final relatedAsync = ref.watch(relatedNewsProvider(RelatedNewsQuery(excludeId: newsId, tickers: tickers)))
        return relatedAsync.when(
          data: (news) {
            if (news.isEmpty) return const SizedBox()
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: '🔗 İlgili Haberler'),
                const SizedBox(height: 8),
                ...news.take(5).map((n) => _RelatedNewsTile(news: n)),
              ],
            )
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        )
      },
    )
  }

  Widget _RelatedNewsTile({required NewsItem news}) {
    final theme = Theme.of(context)
    final sentimentColor = sentimentColor(news.sentimentScore ?? 0)
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 4,
        decoration: BoxDecoration(
          color: sentimentColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(news.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
      subtitle: Text(_sourceName(news.sourceId), style: theme.textTheme.labelSmall),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: () => context.push('/news/${news.id}'),
    )
  }

  Widget _buildLoading(BuildContext context) => AppScaffold(
    title: '',
    child: const Center(child: CircularProgressIndicator()),
  )

  Widget _buildError(BuildContext context, Object error) => AppScaffold(
    title: '',
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          const Text('Haber yüklenemedi'),
        ],
      ),
    ),
  )

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url)
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication)
    }
  }

  Future<void> _shareNews(NewsItem news) async {
    await Share.share('${news.title}\n\n${news.url}')
  }

  String _sourceName(String sourceId) {
    final map = {
      'bloomberght': 'BloombergHT',
      'dunya': 'Dünya',
      'paraanaliz': 'ParaAnaliz',
      'investingtr': 'InvestingTR',
      'mynet_finans': 'Mynet Finans',
      'mynet_borsa': 'Mynet Borsa',
      'kap': 'KAP',
      'youtube': 'YouTube',
    }
    return map[sourceId.toLowerCase()] ?? sourceId
  }

  String _categoryLabel(List<String> tags) {
    if (tags.isEmpty) return 'Genel'
    final priority = ['kap_bildirim', 'ekonomik', 'politik_ic', 'geopolitik_savas', 'kuresel_denge', 'sektor_ozel', 'sirket_ozel']
    for (final p in priority) {
      if (tags.contains(p)) return p.replaceAll('_', ' ').toUpperCase()
    }
    return tags.first.toUpperCase()
  }
}

class _Chip extends StatelessWidget {
  final String label
  final Color color
  final bool isSentiment

  const _Chip({required this.label, required this.color, this.isSentiment = false})

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(isSentiment ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    )
  }
}