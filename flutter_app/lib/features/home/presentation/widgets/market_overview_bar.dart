// ==========================================
// BORSA SİNYAL FLUTTER - MARKET OVERVIEW BAR
// ==========================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils.dart';
import '../../../../data/providers.dart';
import '../../../../data/models/technical_snapshot.dart';

class MarketOverviewBar extends ConsumerWidget {
  const MarketOverviewBar({super.key});

  static const List<_MarketInstrument> _instruments = [
    _MarketInstrument(
      key: 'XU030.IS',
      label: 'BIST 30',
      emoji: '🇹🇷',
      color: Color(0xFF006B3C),
      route: '/technical/XU030.IS',
    ),
    _MarketInstrument(
      key: 'XAGTRY',
      label: 'GÜMÜŞ',
      emoji: '🥈',
      color: Color(0xFF9E9E9E),
      route: '/technical/XAGTRY',
    ),
    _MarketInstrument(
      key: 'XAUTRY',
      label: 'ALTIN',
      emoji: '🥇',
      color: Color(0xFFFFD700),
      route: '/technical/XAUTRY',
    ),
    _MarketInstrument(
      key: 'CL=F',
      label: 'PETROL',
      emoji: '🛢',
      color: Color(0xFF37474F),
      route: '/technical/CL=F',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotsAsync = ref.watch(technicalSnapshotsProvider);
    final lastUpdate = ref.watch(technicalLastUpdateProvider);

    return snapshotsAsync.when(
      data: (snapshots) => _buildBar(context, snapshots, lastUpdate),
      loading: () => _buildSkeleton(context),
      error: (e, _) => _buildError(context, e, ref),
    );
  }

  Widget _buildBar(BuildContext context, Map<String, TechnicalSnapshot> snapshots, DateTime? lastUpdate) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'PİYASA ÖZETİ',
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
                    if (lastUpdate != null)
                      Text(
                        DateFormat('HH:mm:ss', 'tr_TR').format(lastUpdate.toLocal()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Yenile',
                      icon: const Icon(Icons.refresh_outlined, size: 20),
                      onPressed: () => ref.read(technicalSnapshotsProvider.notifier).refresh(),
                    ),
                    IconButton(
                      tooltip: 'Tüm Teknik Analiz',
                      icon: const Icon(Icons.tune_outlined, size: 20),
                      onPressed: () => context.push('/technical'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Instrument Cards - Horizontal Scroll
            SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _instruments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final inst = _instruments[index];
                  final snapshot = snapshots[inst.key];
                  return _InstrumentCard(
                    instrument: inst,
                    snapshot: snapshot,
                    onTap: () => context.push(inst.route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: SizedBox(
        height: 220,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (_, __) => _SkeletonCard(theme: theme),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Piyasa verisi yüklenemedi',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onErrorContainer),
              ),
            ),
            TextButton(
              onPressed: () => ref.read(technicalSnapshotsProvider.notifier).refresh(),
              child: Text('Tekrar Dene', style: TextStyle(color: theme.colorScheme.onErrorContainer)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketInstrument {
  final String key;
  final String label;
  final String emoji;
  final Color color;
  final String route;

  const _MarketInstrument({
    required this.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.route,
  });
}

class _InstrumentCard extends StatelessWidget {
  final _MarketInstrument instrument;
  final TechnicalSnapshot? snapshot;
  final VoidCallback onTap;

  const _InstrumentCard({
    required this.instrument,
    required this.snapshot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasData = snapshot != null;

    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: instrument.color.withOpacity(0.3),
              width: 1.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                instrument.color.withOpacity(0.08),
                instrument.color.withOpacity(0.02),
              ],
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Emoji + Label
              Row(
                children: [
                  Text(instrument.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      instrument.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: instrument.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Mini Sparkline Chart
              SizedBox(
                height: 50,
                child: hasData
                    ? _MiniSparkline(
                        data: snapshot!.sparklineData,
                        color: instrument.color,
                        trendUp: snapshot!.trendLong == 'UP',
                      )
                    : _MiniSparklineSkeleton(color: instrument.color),
              ),

              const SizedBox(height: 8),

              // Price & Change
              if (hasData) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        formatPrice(snapshot!.close),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _ChangeBadge(changePct: snapshot!.changePct),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  formatChange(snapshot!.change, snapshot!.changePct),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: sentimentColor(snapshot!.changePct / 100),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else ...[
                _ShimmerLine(width: 80, height: 20, theme: theme),
                const SizedBox(height: 4),
                _ShimmerLine(width: 100, height: 12, theme: theme),
              ],

              const Spacer(),

              // Key Metrics Row
              if (hasData) ...[
                _MetricRow(
                  label: 'EMA200',
                  value: '${snapshot!.distEma200Pct >= 0 ? "+" : ""}${snapshot!.distEma200Pct.toStringAsFixed(1)}%',
                  color: sentimentColor(snapshot!.distEma200Pct / 100),
                ),
                _MetricRow(
                  label: 'RSI',
                  value: snapshot!.rsi14.toStringAsFixed(0),
                  color: _rsiColor(snapshot!.rsi14),
                ),
                _MetricRow(
                  label: 'Trend',
                  value: _trendLabel(snapshot!.trendLong),
                  color: _trendColor(snapshot!.trendLong),
                ),
              ] else ...[
                _ShimmerLine(width: 140, height: 14, theme: theme),
                const SizedBox(height: 4),
                _ShimmerLine(width: 140, height: 14, theme: theme),
                const SizedBox(height: 4),
                _ShimmerLine(width: 140, height: 14, theme: theme),
              ],

              const SizedBox(height: 8),

              // Detail Button
              Center(
                child: TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: instrument.color,
                  ),
                  child: const Text('Detay ▸', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _trendLabel(String trend) {
    switch (trend) {
      case 'UP': return '🟢 YÜKSELİŞ';
      case 'DOWN': return '🔴 DÜŞÜŞ';
      default: return '⚪ YATAY';
    }
  }

  Color _trendColor(String trend) {
    switch (trend) {
      case 'UP': return Colors.green;
      case 'DOWN': return Colors.red;
      default: return Colors.orange;
    }
  }

  Color _rsiColor(double rsi) {
    if (rsi >= 70) return Colors.red;
    if (rsi <= 30) return Colors.green;
    return Colors.orange;
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<double> data;
  final Color color;
  final bool trendUp;

  const _MiniSparkline({
    required this.data,
    required this.color,
    required this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    if (data.length < 2) return const SizedBox();

    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final range = maxY - minY;
    final normalized = range > 0
        ? spots.map((s) => FlSpot(s.x, (s.y - minY) / range)).toList()
        : spots.map((s) => FlSpot(s.x, 0.5)).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: 0,
        maxY: 1,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: normalized,
            isCurved: true,
            curveSmoothness: 0.35,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSparklineSkeleton extends StatelessWidget {
  final Color color;

  const _MiniSparklineSkeleton({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 50),
      painter: _SparklineSkeletonPainter(color: color),
    );
  }
}

class _SparklineSkeletonPainter extends CustomPainter {
  final Color color;

  _SparklineSkeletonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = 20;
    for (int i = 0; i < points; i++) {
      final x = (i / (points - 1)) * size.width;
      final y = size.height * (0.5 + 0.3 * (i % 3 - 1) * 0.5);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(
            value,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  final double changePct;

  const _ChangeBadge({required this.changePct});

  @override
  Widget build(BuildContext context) {
    final color = sentimentColor(changePct / 100);
    final isUp = changePct >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '${isUp ? "+" : ""}${changePct.toStringAsFixed(2)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final ThemeData theme;

  const _SkeletonCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerLine(width: 60, height: 16, theme: theme),
              const SizedBox(height: 8),
              _ShimmerLine(width: double.infinity, height: 50, theme: theme),
              const SizedBox(height: 8),
              _ShimmerLine(width: 80, height: 20, theme: theme),
              const SizedBox(height: 4),
              _ShimmerLine(width: 100, height: 12, theme: theme),
              const Spacer(),
              _ShimmerLine(width: 140, height: 14, theme: theme),
              const SizedBox(height: 4),
              _ShimmerLine(width: 140, height: 14, theme: theme),
              const SizedBox(height: 4),
              _ShimmerLine(width: 140, height: 14, theme: theme),
              const SizedBox(height: 8),
              _ShimmerLine(width: 60, height: 16, theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}