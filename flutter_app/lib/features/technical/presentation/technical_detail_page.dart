// ==========================================
// BORSA SİNYAL FLUTTER - TECHNICAL DETAIL PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:fl_chart/fl_chart.dart'
import 'package:go_router/go_router.dart'

import '../../../../core/theme/app_theme.dart'
import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/technical_snapshot.dart'
import '../../../../shared/widgets.dart'

class TechnicalDetailPage extends ConsumerStatefulWidget {
  final String symbol

  const TechnicalDetailPage({super.key, required this.symbol})

  @override
  ConsumerState<TechnicalDetailPage> createState() => _TechnicalDetailPageState()
}

class _TechnicalDetailPageState extends ConsumerState<TechnicalDetailPage> {
  @override
  Widget build(BuildContext context) {
    final techAsync = ref.watch(technicalDetailProvider(widget.symbol))

    return techAsync.when(
      data: (tech) => _buildDetail(context, tech),
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, e),
    )
  }

  Widget _buildDetail(BuildContext context, TechnicalSnapshot tech) {
    final theme = Theme.of(context)
    final cleanSymbol = widget.symbol.replaceAll('.IS', '').replaceAll('=X', '').replaceAll('=F', '')
    final directionColor = tech.trendLong == 'UP' ? Colors.green : (tech.trendLong == 'DOWN' ? Colors.red : Colors.orange)

    return AppScaffold(
      title: cleanSymbol,
      actions: [
        IconButton(
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => ref.refresh(technicalDetailProvider(widget.symbol)),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          // Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: directionColor.withOpacity(0.2),
                            child: Icon(
                              tech.trendLong == 'UP' ? Icons.trending_up : (tech.trendLong == 'DOWN' ? Icons.trending_down : Icons.trending_flat),
                              color: directionColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cleanSymbol, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                Text('Son Güncelleme: ${formatTurkishDate(tech.timestamp)}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatPrice(tech.close), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${tech.change >= 0 ? "▲" : "▼"} ${tech.change.abs().toStringAsFixed(2)} (${tech.changePct >= 0 ? "+" : ""}${tech.changePct.toStringAsFixed(2)}%)', style: TextStyle(color: tech.change >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Trend badges
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TrendChip(label: 'Kısa: ${_trendTr(tech.trendShort)}', color: _trendColor(tech.trendShort)),
                          _TrendChip(label: 'Orta: ${_trendTr(tech.trendMedium)}', color: _trendColor(tech.trendMedium)),
                          _TrendChip(label: 'Uzun: ${_trendTr(tech.trendLong)}', color: _trendColor(tech.trendLong)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Price Chart (Sparkline expanded)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fiyat Grafiği (Son 30 Gün)', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _PriceChart(data: tech.sparklineData, color: directionColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Key Metrics Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _MetricsGrid(tech: tech),
            ),
          ),

          // EMA Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _EMADetailsCard(tech: tech),
            ),
          ),

          // Oscillators
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _OscillatorsCard(tech: tech),
            ),
          ),

          // Volume & Support/Resistance
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _VolumeSupportCard(tech: tech),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    )
  }

  String _trendTr(String trend) {
    switch (trend) {
      case 'UP': return 'Yükseliş'
      case 'DOWN': return 'Düşüş'
      default: return 'Yatay'
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'UP': return Colors.green
      case 'DOWN': return Colors.red
      default: return Colors.orange
    }
  }

  Widget _buildLoading(BuildContext context) => AppScaffold(
    title: widget.symbol,
    child: const Center(child: CircularProgressIndicator()),
  )

  Widget _buildError(BuildContext context, Object error) => AppScaffold(
    title: widget.symbol,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text('Teknik veri yüklenemedi: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.refresh(technicalDetailProvider(widget.symbol)),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    ),
  )
}

class _TrendChip extends StatelessWidget {
  final String label
  final Color color

  const _TrendChip({required this.label, required this.color})

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    )
  }
}

class _PriceChart extends StatelessWidget {
  final List<double> data
  final Color color

  const _PriceChart({required this.data, required this.color})

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const Center(child: Text('Veri yok'))

    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList()
    final minY = data.reduce((a, b) => a < b ? a : b)
    final maxY = data.reduce((a, b) => a > b ? a : b)
    final range = maxY - minY
    final normalized = range > 0
        ? spots.map((s) => FlSpot(s.x, (s.y - minY) / range)).toList()
        : spots.map((s) => FlSpot(s.x, 0.5)).toList()

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 1,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.25, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text('${(v * range + minY).toStringAsFixed(0)}', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => v % 5 == 0 ? Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)) : const SizedBox())),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: true, touchTooltipData: LineTouchTooltipData(getTooltipItems: (spots) => spots.map((s) => LineTooltipItem('${(s.y * range + minY).toStringAsFixed(2)}', const TextStyle(color: Colors.white))).toList())),
        lineBarsData: [
          LineChartBarData(
            spots: normalized,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.3), color.withOpacity(0.0)]),
            ),
          ),
        ],
      ),
    )
  }
}

class _MetricsGrid extends StatelessWidget {
  final TechnicalSnapshot tech

  const _MetricsGrid({required this.tech})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final metrics = [
      ('EMA 5', tech.ema5.toStringAsFixed(2), tech.distEma5Pct >= 0 ? Colors.green : Colors.red),
      ('EMA 21', tech.ema21.toStringAsFixed(2), tech.distEma21Pct >= 0 ? Colors.green : Colors.red),
      ('EMA 50', tech.ema50.toStringAsFixed(2), tech.distEma50Pct >= 0 ? Colors.green : Colors.red),
      ('EMA 200', tech.ema200.toStringAsFixed(2), tech.distEma200Pct >= 0 ? Colors.green : Colors.red),
      ('RSI(14)', tech.rsi14.toStringAsFixed(1), _rsiColor(tech.rsi14)),
      ('MACD', tech.macd.toStringAsFixed(4), tech.macd >= tech.macdSignal ? Colors.green : Colors.red),
      ('Sinyal', tech.macdSignal.toStringAsFixed(4), Colors.grey),
      ('Histogram', tech.macdHistogram.toStringAsFixed(4), tech.macdHistogram >= 0 ? Colors.green : Colors.red),
      ('Hacim', tech.volume.toString(), tech.volumeRatio > 1 ? Colors.green : Colors.grey),
      ('Hacim Ort.', tech.volumeAvg20.toString(), Colors.grey),
      ('Destek', tech.support20.toStringAsFixed(2), Colors.green),
      ('Direnç', tech.resistance20.toStringAsFixed(2), Colors.red),
    ]

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Temel Göstergeler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: metrics.length,
          itemBuilder: (_, index) {
            final (label, value, color) = metrics[index]
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
                  ],
                ),
              ),
            )
          },
        ),
      ],
    )
  }
}

Color _rsiColor(double rsi) {
  if (rsi >= 70) return Colors.red
  if (rsi <= 30) return Colors.green
  return Colors.orange
}

class _EMADetailsCard extends StatelessWidget {
  final TechnicalSnapshot tech

  const _EMADetailsCard({required this.tech})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EMA Detayları', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _EmaRow(label: 'EMA 5 (Hızlı)', value: tech.ema5, distance: tech.distEma5Pct),
            _EmaRow(label: 'EMA 21 (Kısa)', value: tech.ema21, distance: tech.distEma21Pct),
            _EmaRow(label: 'EMA 50 (Orta)', value: tech.ema50, distance: tech.distEma50Pct),
            _EmaRow(label: 'EMA 200 (Uzun)', value: tech.ema200, distance: tech.distEma200Pct, isKey: true),
          ],
        ),
      ),
    )
  }
}

class _EmaRow extends StatelessWidget {
  final String label
  final double value
  final double distance
  final bool isKey

  const _EmaRow({required this.label, required this.value, required this.distance, this.isKey = false})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final color = distance >= 0 ? Colors.green : Colors.red
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: isKey ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(formatPrice(value), style: isKey ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text('${distance >= 0 ? "+" : ""}${distance.toStringAsFixed(2)}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    )
  }
}

class _OscillatorsCard extends StatelessWidget {
  final TechnicalSnapshot tech

  const _OscillatorsCard({required this.tech})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Osilatörler', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _OscillatorItem(title: 'RSI (14)', value: tech.rsi14.toStringAsFixed(1), color: _rsiColor(tech.rsi14), zones: ['Aşırı Satım (<30)', 'Nötr (30-70)', 'Aşırı Alım (>70)'], currentZone: tech.rsi14 >= 70 ? 2 : (tech.rsi14 <= 30 ? 0 : 1))),
                const SizedBox(width: 12),
                Expanded(child: _OscillatorItem(title: 'MACD', value: tech.macd.toStringAsFixed(4), color: tech.macdHistogram >= 0 ? Colors.green : Colors.red, zones: ['Negatif', 'Sinyal Çizgisi', 'Pozitif'], currentZone: tech.macdHistogram >= 0 ? 2 : 0)),
              ],
            ),
          ],
        ),
      ),
    )
  }
}

class _OscillatorItem extends StatelessWidget {
  final String title
  final String value
  final Color color
  final List<String> zones
  final int currentZone

  const _OscillatorItem({required this.title, required this.value, required this.color, required this.zones, required this.currentZone})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),
        Row(
          children: zones.asMap().entries.map((e) {
            final isActive = e.key == currentZone
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? color.withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: isActive ? color : Colors.transparent),
                ),
                child: Text(e.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? color : theme.colorScheme.onSurfaceVariant)),
              ),
            )
          }).toList(),
        ),
      ],
    )
  }
}

class _VolumeSupportCard extends StatelessWidget {
  final TechnicalSnapshot tech

  const _VolumeSupportCard({required this.tech})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hacim ve Destek/Direnç', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hacim', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      Text(formatPrice(tech.volume.toDouble()), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: tech.volumeRatio > 1 ? Colors.green : theme.colorScheme.onSurface)),
                      const SizedBox(height: 4),
                      Text('Ortalama: ${formatPrice(tech.volumeAvg20.toDouble())}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: (tech.volumeRatio > 1 ? Colors.green : Colors.grey).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text('Oran: ${tech.volumeRatio.toStringAsFixed(2)}x', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: tech.volumeRatio > 1 ? Colors.green : Colors.grey)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Destek / Direnç', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      _SupportResistanceRow(label: 'Direnç (20g)', value: tech.resistance20, color: Colors.red),
                      const SizedBox(height: 8),
                      _SupportResistanceRow(label: 'Destek (20g)', value: tech.support20, color: Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
  }
}

class _SupportResistanceRow extends StatelessWidget {
  final String label
  final double value
  final Color color

  const _SupportResistanceRow({required this.label, required this.value, required this.color})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Row(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const Spacer(),
        Text(formatPrice(value), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
      ],
    )
  }
}