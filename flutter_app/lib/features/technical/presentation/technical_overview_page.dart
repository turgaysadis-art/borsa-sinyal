// ==========================================
// BORSA SİNYAL FLUTTER - TECHNICAL OVERVIEW PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:go_router/go_router.dart'

import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/technical_snapshot.dart'
import '../../../../shared/widgets.dart'

class TechnicalOverviewPage extends ConsumerWidget {
  const TechnicalOverviewPage({super.key})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(technicalSnapshotsProvider)
    final signalsAsync = ref.watch(technicalSignalsProvider(null))
    final theme = Theme.of(context)

    return AppScaffold(
      title: 'Teknik Analiz',
      actions: [
        IconButton(
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () {
            ref.invalidate(technicalSnapshotsProvider)
            ref.invalidate(technicalSignalsProvider(null))
          },
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(technicalSnapshotsProvider)
          ref.invalidate(technicalSignalsProvider(null))
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('TEKNİK SİNYALLER', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),

            // Signals Grid
            SliverToBoxAdapter(
              child: signalsAsync.when(
                data: (signals) => _SignalsGrid(signals: signals),
                loading: () => _SignalsGridSkeleton(theme: theme),
                error: (e, _) => _buildError(theme, e, ref),
              ),
            ),

            // All Snapshots
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.list_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('TÜM ENSTRÜMANLAR', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: snapshotsAsync.when(
                data: (snapshots) => _SnapshotsList(snapshots: snapshots),
                loading: () => _SnapshotsListSkeleton(theme: theme),
                error: (e, _) => _buildError(theme, e, ref),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    )
  }

  Widget _buildError(ThemeData theme, Object error, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(16),
    child: Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(child: Text('Veri yüklenemedi', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer))),
            TextButton(onPressed: () { ref.invalidate(technicalSnapshotsProvider); ref.invalidate(technicalSignalsProvider(null)); }, child: Text('Tekrar Dene', style: TextStyle(color: theme.colorScheme.onErrorContainer))),
          ],
        ),
      ),
    ),
  )
}

class _SignalsGrid extends StatelessWidget {
  final Map<String, dynamic> signals

  const _SignalsGrid({required this.signals})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final entries = signals.entries.toList()

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: entries.length,
            itemBuilder: (_, index) {
              final entry = entries[index]
              final signal = entry.value as Map<String, dynamic>
              return _SignalCard(symbol: entry.key, signal: signal)
            },
          ),
        ],
      ),
    )
  }
}

class _SignalCard extends StatelessWidget {
  final String symbol
  final Map<String, dynamic> signal

  const _SignalCard({required this.symbol, required this.signal})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final direction = signal['direction'] as String
    final confidence = (signal['confidence'] as num).toDouble()
    final score = (signal['score'] as num).toDouble()
    final cleanSymbol = symbol.replaceAll('.IS', '').replaceAll('=X', '').replaceAll('=F', '')

    final color = direction == 'UP' ? Colors.green : (direction == 'DOWN' ? Colors.red : Colors.orange)
    final icon = direction == 'UP' ? Icons.trending_up : (direction == 'DOWN' ? Icons.trending_down : Icons.trending_flat)

    return Card(
      child: InkWell(
        onTap: () => context.push('/technical/$symbol'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(cleanSymbol, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              Text(direction == 'UP' ? 'YÜKSELİŞ' : (direction == 'DOWN' ? 'DÜŞÜŞ' : 'YATAY'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text('%${(confidence * 100).round()} Güven', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Skor: ${score.toStringAsFixed(2)}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
                  Text('RSI: ${(signal['rsi_14'] as num).toStringAsFixed(0)}', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500, color: _rsiColor((signal['rsi_14'] as num).toDouble()))),
                ],
              ),
            ],
          ),
        ),
      ),
    )
  }

  Color _rsiColor(double rsi) {
    if (rsi >= 70) return Colors.red
    if (rsi <= 30) return Colors.green
    return Colors.orange
  }
}

class _SignalsGridSkeleton extends StatelessWidget {
  final ThemeData theme
  const _SignalsGridSkeleton({required this.theme})

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.6, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: 6,
      itemBuilder: (_, __) => Card(child: _ShimmerBox(width: double.infinity, height: double.infinity, theme: theme)),
    ),
  )
}

class _SnapshotsList extends StatelessWidget {
  final Map<String, TechnicalSnapshot> snapshots

  const _SnapshotsList({required this.snapshots})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final entries = snapshots.entries.toList()

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => Divider(indent: 16, endIndent: 16, height: 1),
      itemBuilder: (_, index) {
        final entry = entries[index]
        return _SnapshotTile(snapshot: entry.value)
      },
    )
  }
}

class _SnapshotTile extends StatelessWidget {
  final TechnicalSnapshot snapshot

  const _SnapshotTile({required this.snapshot})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final cleanSymbol = snapshot.symbol.replaceAll('.IS', '').replaceAll('=X', '').replaceAll('=F', '')
    final directionColor = snapshot.trendLong == 'UP' ? Colors.green : (snapshot.trendLong == 'DOWN' ? Colors.red : Colors.orange)

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: directionColor.withOpacity(0.2),
        child: Text(cleanSymbol.substring(0, 1), style: TextStyle(color: directionColor, fontWeight: FontWeight.bold)),
      ),
      title: Text(cleanSymbol, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text('${formatPrice(snapshot.close)}  |  ${snapshot.changePct >= 0 ? "▲" : "▼"} ${snapshot.changePct.abs().toStringAsFixed(2)}%  |  ${_trendLabel(snapshot.trendLong)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('RSI ${snapshot.rsi14.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _rsiColor(snapshot.rsi14))),
          Text('EMA200 ${snapshot.distEma200Pct >= 0 ? "+" : ""}${snapshot.distEma200Pct.toStringAsFixed(1)}%', style: TextStyle(fontSize: 11, color: sentimentColor(snapshot.distEma200Pct / 100))),
        ],
      ),
      onTap: () => context.push('/technical/${snapshot.symbol}'),
    )
  }

  String _trendLabel(String trend) {
    switch (trend) { case 'UP': return '🟢 Yükseliş'; case 'DOWN': return '🔴 Düşüş'; default: return '⚪ Yatay'; }
  }
}

class _SnapshotsListSkeleton extends StatelessWidget {
  final ThemeData theme
  const _SnapshotsListSkeleton({required this.theme})

  @override
  Widget build(BuildContext context) => ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 6,
    itemBuilder: (_, __) => ListTile(
      leading: _ShimmerBox(width: 40, height: 40, theme: theme),
      title: _ShimmerBox(width: 80, height: 16, theme: theme),
      subtitle: _ShimmerBox(width: 150, height: 12, theme: theme),
    ),
  )
}