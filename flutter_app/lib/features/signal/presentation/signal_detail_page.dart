// ==========================================
// BORSA SİNYAL FLUTTER - SIGNAL DETAIL PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:go_router/go_router.dart'
import 'package:intl/intl.dart'

import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/signal.dart'
import '../../../../shared/widgets.dart'

class SignalDetailPage extends ConsumerWidget {
  final String signalId

  const SignalDetailPage({super.key, required this.signalId})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalAsync = ref.watch(signalDetailProvider(signalId))

    return signalAsync.when(
      data: (signal) => _buildDetail(context, signal),
      loading: () => _buildLoading(context),
      error: (e, _) => _buildError(context, e),
    )
  }

  Widget _buildDetail(BuildContext context, Signal signal) {
    final theme = Theme.of(context)
    final directionColor = signal.directionColor

    return AppScaffold(
      title: '',
      actions: [
        IconButton(
          tooltip: 'Paylaş',
          icon: const Icon(Icons.share_outlined),
          onPressed: () => _shareSignal(signal),
        ),
      ],
      child: CustomScrollView(
        slivers: [
          // Hero Header
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      directionColor.withOpacity(0.2),
                      directionColor.withOpacity(0.05),
                    ],
                  ),
                  border: Border(bottom: BorderSide(color: directionColor.withOpacity(0.3))),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: directionColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: Icon(signal.directionIcon, color: directionColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(signal.directionLabel, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: directionColor)),
                              Text(DateFormat('d MMMM yyyy', 'tr_TR').format(signal.date.toLocal()), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('%${(signal.confidence * 100).round()}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: directionColor)),
                            Text('Güven', style: theme.textTheme.labelSmall?.copyWith(color: directionColor)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: signal.confidence, minHeight: 6, backgroundColor: directionColor.withOpacity(0.2), valueColor: AlwaysStoppedAnimation(directionColor)),
                  ],
                ),
              ),
            ),

          // Açıklama
          if (signal.components['explanation'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📋 SİNYAL AÇIKLAMASI', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        const SizedBox(height: 8),
                        Text(signal.components['explanation'] as String, style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)),
                      ],
                    ),
                  ),
                ),
            ),

          // Ana Sürücüler
          if (signal.components['key_drivers'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _DriverCard(
                  title: '✅ POZİTİF ETKİLER',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  items: List<String>.from(signal.components['key_drivers'] as List),
                ),
              ),
            ),

          // Risk Faktörleri
          if (signal.components['risk_factors'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _DriverCard(
                  title: '⚠ RİSK FAKTÖRLERİ',
                  icon: Icons.warning_outlined,
                  color: Colors.red,
                  items: List<String>.from(signal.components['risk_factors'] as List),
                ),
              ),
            ),

          // Bileşen Skorları
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _ComponentsCard(components: signal.components),
            ),
          ),

          // Kaynak Dağılımı
          if (signal.components['source_breakdown'] != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _SourceBreakdownCard(breakdown: Map<String, dynamic>.from(signal.components['source_breakdown'] as Map)),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    )
  }

  Widget _buildLoading(BuildContext context) => AppScaffold(title: '', child: const Center(child: CircularProgressIndicator()))

  Widget _buildError(BuildContext context, Object error) => AppScaffold(title: '', child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error), const SizedBox(height: 16), Text('Sinyal yüklenemedi: $error')])))

  void _shareSignal(Signal signal) {
    // share_plus kullan
  }
}

class _DriverCard extends StatelessWidget {
  final String title
  final IconData icon
  final Color color
  final List<String> items

  const _DriverCard({required this.title, required this.icon, required this.color, required this.items})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color))]),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.arrow_right, color: color, size: 20), const SizedBox(width: 8), Expanded(child: Text(item, style: theme.textTheme.bodyMedium))]))),
          ],
        ),
      ),
    )
  }
}

class _ComponentsCard extends StatelessWidget {
  final Map<String, dynamic> components

  const _ComponentsCard({required this.components})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final comps = {
      'Haber': components['news'] as double? ?? 0,
      'KAP': components['kap'] as double? ?? 0,
      'Teknik': components['technical'] as double? ?? 0,
      'Ses/Video': components['audio'] as double? ?? 0,
      'Makro': components['macro'] as double? ?? 0,
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BİLEŞEN SKORLARI', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            ...comps.entries.map((e) => _ComponentBar(label: e.key, score: e.value, weight: (components['fusion_weights'] as Map?)?[e.key.toLowerCase()] ?? 0)),
          ],
        ),
      ),
    )
  }
}

class _ComponentBar extends StatelessWidget {
  final String label
  final double score
  final double weight

  const _ComponentBar({required this.label, required this.score, required this.weight})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final color = score > 0 ? Colors.green : (score < 0 ? Colors.red : Colors.orange)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)), Text('${score > 0 ? "+" : ""}${score.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color))]),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: (score + 1) / 2, minHeight: 6, backgroundColor: color.withOpacity(0.1), valueColor: AlwaysStoppedAnimation(color)),
          const SizedBox(height: 2),
          Text('Ağırlık: %${(weight * 100).toStringAsFixed(0)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    )
  }
}

class _SourceBreakdownCard extends StatelessWidget {
  final Map<String, dynamic> breakdown

  const _SourceBreakdownCard({required this.breakdown})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('KAYNAK DAĞILIMI', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            ...breakdown.entries.map((e) {
              final data = e.value as Map<String, dynamic>
              final count = data['count'] as int? ?? 0
              final avg = (data['avg_sentiment'] as num?)?.toDouble() ?? 0
              final weight = (data['weight'] as num?)?.toDouble() ?? 0
              final color = avg > 0 ? Colors.green : (avg < 0 ? Colors.red : Colors.orange)
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500))),
                    Text('$count haber', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(width: 12),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('${avg >= 0 ? "+" : ""}${avg.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color))),
                    const SizedBox(width: 8),
                    Text('%${(weight * 100).toStringAsFixed(0)}', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                )
              ),
            ),
          ],
        ),
      ),
    )
  }
}