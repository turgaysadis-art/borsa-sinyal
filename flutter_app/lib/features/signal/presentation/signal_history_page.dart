// ==========================================
// BORSA SİNYAL FLUTTER - SIGNAL HISTORY PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:go_router/go_router.dart'
import 'package:intl/intl.dart'

import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/signal.dart'
import '../../../../shared/widgets.dart'

class SignalHistoryPage extends ConsumerStatefulWidget {
  const SignalHistoryPage({super.key})

  @override
  ConsumerState<SignalHistoryPage> createState() => _SignalHistoryPageState()
}

class _SignalHistoryPageState extends ConsumerState<SignalHistoryPage> {
  final _scrollController = ScrollController()
  String _filterDirection = 'Tümü' // 'Tümü', 'UP', 'DOWN', 'FLAT'

  @override
  void initState() {
    super.initState()
    _scrollController.addListener(_onScroll)
  }

  @override
  void dispose() {
    _scrollController.dispose()
    super.dispose()
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(signalHistoryControllerProvider.notifier).loadMore()
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signalHistoryControllerProvider)
    final theme = Theme.of(context)

    // Filtreleme
    final filteredHistory = state.history.where((s) {
      if (_filterDirection == 'Tümü') return true
      return s.direction == _filterDirection
    }).toList()

    return AppScaffold(
      title: 'Sinyal Geçmişi',
      actions: [
        PopupMenuButton<String>(
          initialValue: _filterDirection,
          onSelected: (value) => setState(() => _filterDirection = value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'Tümü', child: Text('Tümü')),
            const PopupMenuItem(value: 'UP', child: Row(children: [Icon(Icons.trending_up, color: Colors.green, size: 20), SizedBox(width: 8), Text('Yükseliş')])),
            const PopupMenuItem(value: 'DOWN', child: Row(children: [Icon(Icons.trending_down, color: Colors.red, size: 20), SizedBox(width: 8), Text('Düşüş')])),
            const PopupMenuItem(value: 'FLAT', child: Row(children: [Icon(Icons.trending_flat, color: Colors.orange, size: 20), SizedBox(width: 8), Text('Yatay')])),
          ],
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Text(_filterDirection, style: theme.textTheme.labelMedium), const SizedBox(width: 4), Icon(Icons.filter_list, size: 20)]),
          ),
        ),
        IconButton(
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh_outlined),
          onPressed: () => ref.read(signalHistoryControllerProvider.notifier).refresh(),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.read(signalHistoryControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Özet İstatistikler
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _StatsRow(
                  total: state.history.length,
                  up: state.history.where((s) => s.direction == 'UP').length,
                  down: state.history.where((s) => s.direction == 'DOWN').length,
                  flat: state.history.where((s) => s.direction == 'FLAT').length,
                ),
              ),
            ),

            // Liste
            if (filteredHistory.isEmpty && !state.isLoading)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('Bu filtrede sinyal yok', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('Filtreyi değiştirin veya yeni sinyal bekleyin', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
                    ],
                  ),
                ),
              )
            else
              SliverList.separated(
                itemCount: filteredHistory.length + (state.isLoadingMore ? 1 : 0),
                separatorBuilder: (_, __) => Divider(indent: 16, endIndent: 16, height: 1),
                itemBuilder: (_, index) {
                  if (index == filteredHistory.length) {
                    return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  }
                  final signal = filteredHistory[index]
                  return _SignalHistoryTile(
                    signal: signal,
                    onTap: () => context.push('/signal/${signal.id}'),
                  )
                },
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    )
  }
}

class _StatsRow extends StatelessWidget {
  final int total
  final int up
  final int down
  final int flat

  const _StatsRow({required this.total, required this.up, required this.down, required this.flat})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Toplam', value: total.toString(), color: theme.colorScheme.primary, icon: Icons.analytics)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Yükseliş', value: up.toString(), color: Colors.green, icon: Icons.trending_up)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Düşüş', value: down.toString(), color: Colors.red, icon: Icons.trending_down)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'Yatay', value: flat.toString(), color: Colors.orange, icon: Icons.trending_flat)),
      ],
    )
  }
}

class _StatCard extends StatelessWidget {
  final String label
  final String value
  final Color color
  final IconData icon

  const _StatCard({required this.label, required this.value, required this.color, required this.icon})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    )
  }
}

class _SignalHistoryTile extends StatelessWidget {
  final Signal signal
  final VoidCallback? onTap

  const _SignalHistoryTile({required this.signal, this.onTap})

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    final directionColor = signal.directionColor

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: directionColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
        child: Icon(signal.directionIcon, color: directionColor, size: 22),
      ),
      title: Text(signal.directionLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: directionColor)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(DateFormat('d MMMM yyyy - HH:mm', 'tr_TR').format(signal.date.toLocal()), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          if (signal.components['explanation'] != null)
            Text(signal.components['explanation'] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('%${(signal.confidence * 100).round()}', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: directionColor)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: directionColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
            child: Text(signal.direction == 'UP' ? '▲' : (signal.direction == 'DOWN' ? '▼' : '●'), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: directionColor)),
          ),
        ],
      ),
      onTap: onTap,
    )
  }
}

// Signal History Controller
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:riverpod_annotation/riverpod_annotation.dart'

import '../../../data/providers.dart'
import '../../../data/models/signal.dart'

part 'signal_history_controller.g.dart'

@riverpod
class SignalHistoryController extends _$SignalHistoryController {
  @override
  SignalHistoryState build() {
    return const SignalHistoryState()
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true)
    try {
      final signals = await ref.read(signalsProvider(SignalsQuery(limit: 50)).future)
      state = state.copyWith(isLoading: false, history: signals)
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString())
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, error: null)
    ref.invalidate(signalsProvider(SignalsQuery(limit: 50)))
    await loadInitial()
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore) return
    state = state.copyWith(isLoadingMore: true)
    try {
      final offset = state.history.length
      final more = await ref.read(signalsProvider(SignalsQuery(limit: 50, offset: offset)).future)
      state = state.copyWith(isLoadingMore: false, history: [...state.history, ...more])
    } catch (e) {
      state = state.copyWith(isLoadingMore: false)
    }
  }
}

class SignalHistoryState {
  final bool isLoading
  final bool isLoadingMore
  final String? error
  final List<Signal> history

  const SignalHistoryState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.history = const [],
  })

  SignalHistoryState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<Signal>? history,
  }) {
    return SignalHistoryState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      history: history ?? this.history,
    )
  }
}