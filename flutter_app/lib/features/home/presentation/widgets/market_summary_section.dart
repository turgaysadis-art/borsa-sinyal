// ==========================================
// BORSA SİNYAL FLUTTER - MARKET SUMMARY SECTION
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/market_summary.dart'
import '../../../../shared/widgets.dart'

class MarketSummarySection extends ConsumerWidget {
  const MarketSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(marketSummaryProvider);
    final theme = Theme.of(context);

    return summaryAsync.when(
      data: (summary) => _buildSection(context, theme, summary),
      loading: () => _buildSkeleton(theme),
      error: (e, _) => _buildError(theme, e, ref),
    );
  }

  Widget _buildSection(BuildContext context, ThemeData theme, MarketSummary summary) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pie_chart_outline, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'GENEL BİST DURUMU',
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
                  // Sektör filtresi dropdown
                  _SectorFilterDropdown(
                    selectedSector: ref.watch(selectedSectorProvider),
                    onChanged: (s) => ref.read(selectedSectorProvider.notifier).state = s,
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => context.push('/market-summary'),
                    child: const Text('Tümü'),
                  ),
                ],
              ),
            ),
          ),

          // Dörtlü Grid: Yükselen / Düşen / Dengeli / Sektörler
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // İlk satır: Yükselen - Düşen
                Row(
                  children: [
                    Expanded(child: _StockListCard(title: '📈 YÜKSELEN', stocks: summary.topGainers, color: Colors.green, showChange: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _StockListCard(title: '🔴 DÜŞEN', stocks: summary.topLosers, color: Colors.red, showChange: true)),
                  ],
                ),
                const SizedBox(height: 12),
                // İkinci satır: Dengeli - Sektörler
                Row(
                  children: [
                    Expanded(child: _StockListCard(title: '⚖ DENGELİ', stocks: summary.neutral, color: Colors.orange, showChange: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _SectorPerformanceCard(sectors: summary.sectors)),
                  ],
                ),
                const SizedBox(height: 12),
                // Endeks Performans Barı
                _IndicesPerformanceBar(indices: summary.indices),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ),
      ],
    );
  }

  Widget _buildSkeleton(ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Column(
      children: [
        _SectionHeaderSkeleton(theme: theme),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _CardSkeleton(theme)), const SizedBox(width: 12), Expanded(child: _CardSkeleton(theme))]),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _CardSkeleton(theme)), const SizedBox(width: 12), Expanded(child: _CardSkeleton(theme))]),
        const SizedBox(height: 12),
        _CardSkeleton(theme),
      ],
    ),
  );

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
            Expanded(child: Text('Piyasa özeti yüklenemedi', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer))),
            TextButton(onPressed: () => ref.refresh(marketSummaryProvider), child: Text('Tekrar Dene', style: TextStyle(color: theme.colorScheme.onErrorContainer))),
          ],
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// ALT WIDGET'LAR
// ═══════════════════════════════════════════════════════════════

class _SectorFilterDropdown extends StatelessWidget {
  final String selectedSector;
  final ValueChanged<String> onChanged;

  const _SectorFilterDropdown({
    required this.selectedSector,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      initialValue: selectedSector,
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'Tümü', child: Text('Tümü')),
        const PopupMenuItem(value: 'Banka', child: Text('🏦 Banka')),
        const PopupMenuItem(value: 'Holding', child: Text('🏭 Holding')),
        const PopupMenuItem(value: 'Teknoloji', child: Text('💻 Teknoloji')),
        const PopupMenuItem(value: 'Enerji', child: Text('⛽ Enerji')),
        const PopupMenuItem(value: 'Metal', child: Text('⛏ Metal')),
        const PopupMenuItem(value: 'Perakende', child: Text('🛒 Perakende')),
        const PopupMenuItem(value: 'Otomotiv', child: Text('🚗 Otomotiv')),
        const PopupMenuItem(value: 'İlaç', child: Text('💊 İlaç')),
        const PopupMenuItem(value: 'Telekom', child: Text('📡 Telekom')),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedSector, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _StockListCard extends StatelessWidget {
  final String title;
  final List<StockSnapshot> stocks;
  final Color color;
  final bool showChange;

  const _StockListCard({
    required this.title,
    required this.stocks,
    required this.color,
    this.showChange = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayStocks = stocks.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Text('${stocks.length} hisse', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            // Liste
            ...displayStocks.map((s) => _StockRow(stock: s, color: color, showChange: showChange)),
            if (stocks.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: Text('+${stocks.length - 5} daha...', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final StockSnapshot stock;
  final Color color;
  final bool showChange;

  const _StockRow({required this.stock, required this.color, this.showChange = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = stock.changePct > 0;
    final changeColor = isUp ? Colors.green : (stock.changePct < 0 ? Colors.red : Colors.orange);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Sembol
          SizedBox(
            width: 50,
            child: Text(
              stock.symbol.replaceAll('.IS', ''),
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Fiyat
          Expanded(
            child: Text(
              _formatPrice(stock.price),
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Değişim
          if (showChange)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: changeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${isUp ? "▲" : "▼"} ${stock.changePct.abs().toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: changeColor),
              ),
            ),
        ],
      );
    }

    String _formatPrice(double price) {
      if (price >= 1000) return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[0]},');
      if (price >= 10) return price.toStringAsFixed(2);
      return price.toStringAsFixed(3);
    }
  }
}

class _SectorPerformanceCard extends StatelessWidget {
  final Map<String, double> sectors;

  const _SectorPerformanceCard({required this.sectors});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedSectors = sectors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            ...sortedSectors.take(6).map((e) => _SectorRow(sector: e.key, changePct: e.value)),
          ],
        ),
      ),
    );
  }
}

class _SectorRow extends StatelessWidget {
  final String sector;
  final double changePct;

  const _SectorRow({required this.sector, required this.changePct});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = changePct > 0;
    final color = isUp ? Colors.green : (changePct < 0 ? Colors.red : Colors.orange);
    final icon = isUp ? '▲' : (changePct < 0 ? '▼' : '●');

    // Sektör ikonu
    final icons = {
      'Banka': '🏦', 'Holding': '🏭', 'Teknoloji': '💻', 'Enerji': '⛽',
      'Metal': '⛏', 'Perakende': '🛒', 'Otomotiv': '🚗', 'İlaç': '💊',
      'Telekom': '📡', 'Gıda': '🍞', 'İçecek': '🥤', 'Sigorta': '🛡',
      'Cam': '🪟', 'Havacılık': '✈️', 'Petrokimya': '🧪', 'Diğer': '📦',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(icons[sector] ?? '📦', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(sector, style: theme.textTheme.labelMedium?.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('$icon ${changePct.abs().toStringAsFixed(1)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      );
    }
  }
}

class _IndicesPerformanceBar extends StatelessWidget {
  final Map<String, dynamic> indices;

  const _IndicesPerformanceBar({required this.indices});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indexList = indices.entries.toList()
      ..sort((a, b) => (b.value['change_pct'] as double).compareTo(a.value['change_pct'] as double));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('📈 ENDEKS PERFORMANSI', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: indexList.map((e) {
                  final data = e.value as Map<String, dynamic>;
                  final change = data['change_pct'] as double;
                  final isUp = change > 0;
                  final color = isUp ? Colors.green : (change < 0 ? Colors.red : Colors.orange);
                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(e.key.replaceAll('BIST ', ''), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text('${data['value']?.toStringAsFixed(0) ?? '-'}', style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('${isUp ? "▲" : "▼"} ${change.abs().toStringAsFixed(2)}%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton widget'ları
class _SectionHeaderSkeleton extends StatelessWidget {
  final ThemeData theme;
  const _SectionHeaderSkeleton({required this.theme});
  @override Widget build(BuildContext context) => _ShimmerLine(width: 150, height: 16, theme: theme);
}

class _CardSkeleton extends StatelessWidget {
  final ThemeData theme;
  const _CardSkeleton({required this.theme});
  @override Widget build(BuildContext context) => Expanded(child: Card(child: _ShimmerLine(width: double.infinity, height: 120, theme: theme)));
}

class _ShimmerLine extends StatefulWidget {
  final double width; final double height; final ThemeData theme;
  const _ShimmerLine({required this.width, required this.height, required this.theme});
  @override State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat();
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, _) => Container(width: widget.width, height: widget.height, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), gradient: LinearGradient(begin: Alignment(-1.0 + _c.value * 2, 0), end: Alignment(1.0 + _c.value * 2, 0), colors: [widget.theme.colorScheme.surfaceContainerHighest, widget.theme.colorScheme.surfaceContainer, widget.theme.colorScheme.surfaceContainerHighest], stops: const [0.0, 0.5, 1.0]))));
}