// ==========================================
// BORSA SİNYAL FLUTTER - MARKET SUMMARY PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'

import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/market_summary.dart'
import '../../../../shared/widgets.dart'

class MarketSummaryPage extends ConsumerWidget {
  const MarketSummaryPage({super.key})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(marketSummaryProvider)
    final theme = Theme.of(context)

    return AppScaffold(
      title: 'Genel BIST Durumu',
      actions: [
        IconButton(
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => ref.invalidate(marketSummaryProvider),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(marketSummaryProvider.future),
        child: summaryAsync.when(
          data: (summary) => _buildDetail(context, theme, summary),
          loading: () => _buildLoading(theme),
          error: (e, _) => _buildError(theme, e, ref),
        ),
      ),
    )
  }

  Widget _buildDetail(BuildContext context, ThemeData theme, MarketSummary summary) {
    return CustomScrollView(
      slivers: [
        // Yükselen / Düşen / Dengeli
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.pie_chart_outline, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('HİSSE HAREKETLERİ', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _StockListCard(title: '📈 YÜKSELEN', stocks: summary.topGainers, color: Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _StockListCard(title: '🔴 DÜŞEN', stocks: summary.topLosers, color: Colors.red)),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(child: _StockListCard(title: '⚖ DENGELİ', stocks: summary.neutral, color: Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _SectorPerformanceCard(sectors: summary.sectors)),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Endeks Performans
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(Icons.trending_up, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('ENDEKS PERFORMANSI', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: _IndicesPerformanceBar(indices: summary.indices),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Piyasa Genişliği
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Icon(Icons.analytics_outlined, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('PİYASA GENİŞLİĞİ', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MarketBreadthCard(
              advancing: summary.advancing,
              declining: summary.declining,
              unchanged: summary.unchanged,
              breadth: summary.marketBreadth,
              totalVolume: summary.totalVolume,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    )
  }

  Widget _buildLoading(ThemeData theme) => Center(child: CircularProgressIndicator())

  Widget _buildError(ThemeData theme, Object error, WidgetRef ref) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Veri yüklenemedi: $error'),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => ref.invalidate(marketSummaryProvider), child: const Text('Tekrar Dene')),
      ],
    ),
  )
}

class _StockListCard extends StatelessWidget {
  final String title
  final List<StockSnapshot> stocks
  final Color color

  const _StockListCard({required this.title, required this.stocks, required this.color})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final displayStocks = stocks.take(8).toList()

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Text('${stocks.length} hisse', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            ...displayStocks.map((s) => _StockRow(stock: s)),
          ],
        ),
      ),
    )
  }
}

class _StockRow extends StatelessWidget {
  final StockSnapshot stock

  const _StockRow({required this.stock})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final isUp = stock.changePct > 0
    final changeColor = isUp ? Colors.green : (stock.changePct < 0 ? Colors.red : Colors.orange)

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 45, child: Text(stock.symbol.replaceAll('.IS', ''), style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(child: Text(_formatPrice(stock.price), style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 11), overflow: TextOverflow.ellipsis)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: changeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('${isUp ? "▲" : "▼"} ${stock.changePct.abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: changeColor)),
          ),
        ],
      )
    }

    String _formatPrice(double price) {
      if (price >= 1000) return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[0]},')
      if (price >= 10) return price.toStringAsFixed(2)
      return price.toStringAsFixed(3)
    }
  }
}

class _SectorPerformanceCard extends StatelessWidget {
  final Map<String, double> sectors

  const _SectorPerformanceCard({required this.sectors})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final sortedSectors = sectors.entries.toList()..sort((a, b) => b.value.compareTo(a.value))

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('📊 SEKTÖRLER', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                const Spacer(),
                Text('${sectors.length} sektor', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            ...sortedSectors.map((e) => _SectorRow(sector: e.key, changePct: e.value)),
          ],
        ),
      ),
    )
  }
}

class _SectorRow extends StatelessWidget {
  final String sector
  final double changePct

  const _SectorRow({required this.sector, required this.changePct})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final isUp = changePct > 0
    final color = isUp ? Colors.green : (changePct < 0 ? Colors.red : Colors.orange)
    final icon = isUp ? '▲' : (changePct < 0 ? '▼' : '●')

    final icons = {
      'Banka': '🏦', 'Holding': '🏭', 'Teknoloji': '💻', 'Enerji': '⛽',
      'Metal': '⛏', 'Perakende': '🛒', 'Otomotiv': '🚗', 'İlaç': '💊',
      'Telekom': '📡', 'Gıda': '🍞', 'İçecek': '🥤', 'Sigorta': '🛡',
      'Cam': '🪟', 'Havacılık': '✈️', 'Petrokimya': '🧪', 'Diğer': '📦',
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icons[sector] ?? '📦', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(child: Text(sector, style: theme.textTheme.labelMedium?.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis)),
          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('$icon ${changePct.abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color))),
        ],
      )
    )
  }
}

class _IndicesPerformanceBar extends StatelessWidget {
  final Map<String, dynamic> indices

  const _IndicesPerformanceBar({required this.indices})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final indexList = indices.entries.toList()..sort((a, b) => (b.value['change_pct'] as double).compareTo(a.value['change_pct'] as double))

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: indexList.map((e) {
                  final data = e.value as Map<String, dynamic>
                  final change = data['change_pct'] as double
                  final isUp = change > 0
                  final color = isUp ? Colors.green : (change < 0 ? Colors.red : Colors.orange)
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
                    child: Column(
                      children: [
                        Text(e.key.replaceAll('BIST ', ''), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('${data['value']?.toStringAsFixed(0) ?? '-'}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('${isUp ? "▲" : "▼"} ${change.abs().toStringAsFixed(2)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  )
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    )
  }
}

class _MarketBreadthCard extends StatelessWidget {
  final int advancing
  final int declining
  final int unchanged
  final double breadth
  final int totalVolume

  const _MarketBreadthCard({required this.advancing, required this.declining, required this.unchanged, required this.breadth, required this.totalVolume})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final total = advancing + declining + unchanged

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Genel Piyasa Genişliği', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _BreadthStat(label: 'Yükselen', value: advancing.toString(), color: Colors.green, icon: Icons.trending_up)),
                Expanded(child: _BreadthStat(label: 'Düşen', value: declining.toString(), color: Colors.red, icon: Icons.trending_down)),
                Expanded(child: _BreadthStat(label: 'Değişmez', value: unchanged.toString(), color: Colors.orange, icon: Icons.trending_flat)),
                Expanded(child: _BreadthStat(label: 'Genişlik', value: '%${(breadth * 100).toStringAsFixed(1)}', color: breadth > 0.5 ? Colors.green : Colors.red, icon: Icons.balance)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Toplam Hacim', style: theme.textTheme.bodyMedium),
                Text(formatPrice(totalVolume.toDouble()), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    )
  }
}

class _BreadthStat extends StatelessWidget {
  final String label
  final String value
  final Color color
  final IconData icon

  const _BreadthStat({required this.label, required this.value, required this.color, required this.icon})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    )
  }
}