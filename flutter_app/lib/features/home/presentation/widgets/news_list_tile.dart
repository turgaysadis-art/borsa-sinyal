// ==========================================
// BORSA SİNYAL FLUTTER - NEWS LIST TILE
// ==========================================
import 'package:flutter/material.dart'
import 'package:go_router/go_router.dart'

import '../../../../core/utils.dart'
import '../../../../data/models/news_item.dart'
import '../../../../shared/widgets.dart'

class NewsListTile extends StatelessWidget {
  final NewsItem news;

  const NewsListTile({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentimentColor = sentimentColor(news.sentimentScore ?? 0)

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 4,
        decoration: BoxDecoration(
          color: sentimentColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        news.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              _Badge(
                label: _sourceShortName(news.sourceId),
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              _Badge(
                label: formatRelativeTime(news.publishedAt),
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              _Badge(
                label: _categoryLabel(news.tags),
                color: sentimentColor,
              ),
              const SizedBox(width: 6),
              _Badge(
                label: '${(news.sentimentScore ?? 0).toStringAsFixed(2)}',
                color: sentimentColor,
                isSentiment: true,
              ),
            ],
          ),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
      onTap: () => context.push('/news/${news.id}'),
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

class _Badge extends StatelessWidget {
  final String label
  final Color color
  final bool isSentiment

  const _Badge({
    required this.label
    required this.color
    this.isSentiment = false,
  })

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
    )
  }
}