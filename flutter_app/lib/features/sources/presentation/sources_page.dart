// ==========================================
// BORSA SİNYAL FLUTTER - SOURCES PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:go_router/go_router.dart'

import '../../../../core/utils.dart'
import '../../../../data/providers.dart'
import '../../../../data/models/news_source.dart'
import '../../../../shared/widgets.dart'

class SourcesPage extends ConsumerStatefulWidget {
  const SourcesPage({super.key})

  @override
  ConsumerState<SourcesPage> createState() => _SourcesPageState()
}

class _SourcesPageState extends ConsumerState<SourcesPage> {
  @override
  void initState() {
    super.initState()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sourcesProvider.notifier).loadSources()
    })
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sourcesProvider)
    final theme = Theme.of(context)

    return AppScaffold(
      title: 'Haber Kaynakları',
      actions: [
        IconButton(
          tooltip: 'Yeni Kaynak Ekle',
          icon: const Icon(Icons.add_outlined),
          onPressed: () => _showAddSourceDialog(context),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: () => ref.read(sourcesProvider.notifier).loadSources(),
        child: state.when(
          data: (sources) => _buildList(context, theme, sources),
          loading: () => _buildLoading(theme),
          error: (e, _) => _buildError(theme, e, ref),
        ),
      ),
    )
  }

  Widget _buildList(BuildContext context, ThemeData theme, List<NewsSource> sources) {
    if (sources.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          Center(
            child: Column(
              children: [
                Icon(Icons.rss_feed_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3)),
                const SizedBox(height: 16),
                Text('Henüz kaynak yok', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Text('Sağ üstten yeni kaynak ekleyin', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7))),
              ],
            ),
          ),
        ),
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) => _SourceTile(source: sources[index]),
    )
  }

  Widget _buildLoading(ThemeData theme) => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 5,
    itemBuilder: (_, __) => _SourceTileSkeleton(theme: theme),
  )

  Widget _buildError(ThemeData theme, Object error, WidgetRef ref) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text('Kaynaklar yüklenemedi: $error'),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => ref.read(sourcesProvider.notifier).loadSources(), child: const Text('Tekrar Dene')),
      ],
    ),
  )

  Future<void> _showAddSourceDialog(BuildContext context) async {
    final nameController = TextEditingController()
    final urlController = TextEditingController()
    String selectedType = 'rss'
    double weight = 0.8
    bool enabled = true

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Kaynak Ekle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'İsim *', hintText: 'Örn: BloombergHT')),
              const SizedBox(height: 12),
              TextField(controller: urlController, decoration: const InputDecoration(labelText: 'URL *', hintText: 'https://...')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Tip *'),
                items: const [
                  DropdownMenuItem(value: 'rss', child: Text('RSS')),
                  DropdownMenuItem(value: 'youtube', child: Text('YouTube')),
                  DropdownMenuItem(value: 'kap', child: Text('KAP')),
                  DropdownMenuItem(value: 'custom', child: Text('Özel')),
                ],
                onChanged: (v) => selectedType = v ?? 'rss',
              ),
              const SizedBox(height: 12),
              Row(children: [Text('Ağırlık: ${weight.toStringAsFixed(1)}'), const Spacer(), Slider(value: weight, min: 0.1, max: 2.0, divisions: 19, label: weight.toStringAsFixed(1), onChanged: (v) => weight = v)]),
              const SizedBox(height: 8),
              SwitchListTile(title: const Text('Aktif'), value: enabled, onChanged: (v) => enabled = v, contentPadding: EdgeInsets.zero),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(onPressed: () => _addSource(ctx, nameController, urlController, selectedType, weight, enabled), child: const Text('Ekle')),
        ],
      ),
    )
  }

  Future<void> _addSource(BuildContext dialogContext, TextEditingController name, TextEditingController url, String type, double weight, bool enabled) async {
    if (name.text.isEmpty || url.text.isEmpty) return
    
    Navigator.pop(dialogContext)
    
    try {
      await ref.read(sourceRepositoryProvider).createSource(NewsSource(
        id: '',
        name: name.text.trim(),
        type: type,
        url: url.text.trim(),
        enabled: enabled,
        weight: weight,
        config: {},
      ))
      
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Kaynak eklendi')))
        ref.invalidate(sourcesProvider)
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Hata: $e')))
      }
    }
  }
}

class _SourceTile extends ConsumerWidget {
  final NewsSource source

  const _SourceTile({required this.source})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context)
    final typeColor = _typeColor(source.type)

    return Card(
      child: InkWell(
        onTap: () => _showSourceOptions(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Type Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(_typeIcon(source.type), color: typeColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(source.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        if (source.enabled)
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('AKTIF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green)))
                        else
                          Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: const Text('PASİF', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(source.url, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Badge(label: '%${(source.weight * 100).toStringAsFixed(0)} ağırlık', color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        if (source.lastFetchedAt != null)
                          _Badge(label: 'Son: ${formatRelativeTime(source.lastFetchedAt!)}', color: theme.colorScheme.secondary),
                        if (source.lastError != null)
                          _Badge(label: 'Hata: ${source.lastError!.substring(0, 20)}...', color: Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: (value) => _handleAction(context, ref, value),
                itemBuilder: (ctx) => [
                  PopupMenuItem(value: 'toggle', child: Row(children: [Icon(source.enabled ? Icons.pause_circle : Icons.play_circle, size: 20), const SizedBox(width: 8), Text(source.enabled ? 'Devre Dışı Bırak' : 'Etkinleştir')])),
                  PopupMenuItem(value: 'test', child: const Row(children: [Icon(Icons.science_outlined, size: 20), SizedBox(width: 8), Text('Test Et')])),
                  PopupMenuItem(value: 'edit', child: const Row(children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text('Düzenle')])),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 20), const SizedBox(width: 8), Text('Sil', style: TextStyle(color: Colors.red))])),
                ],
                child: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    )
  }

  Color _typeColor(String type) {
    switch (type) { case 'rss': return Colors.blue; case 'youtube': return Colors.red; case 'kap': return Colors.purple; default: return Colors.grey; }
  }

  IconData _typeIcon(String type) {
    switch (type) { case 'rss': return Icons.rss_feed; case 'youtube': return Icons.play_circle; case 'kap': return Icons.verified; default: return Icons.link; }
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    switch (action) {
      case 'toggle':
        await ref.read(sourceRepositoryProvider).toggleSource(source.id)
        ref.invalidate(sourcesProvider)
        break
      case 'test':
        _showTestDialog(context, ref)
        break
      case 'edit':
        _showEditDialog(context)
        break
      case 'delete':
        _confirmDelete(context, ref)
        break
    }
  }

  Future<void> _showTestDialog(BuildContext context, WidgetRef ref) async {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Kaynak Test Ediliyor...'), content: const Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Lütfen bekleyin...')])))
    try {
      final result = await ref.read(sourceRepositoryProvider).testSource(source.id)
      if (context.mounted) {
        Navigator.pop(context)
        showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(result['status'] == 'success' ? 'Başarılı' : 'Hata'), content: Text('${result['fetched_count'] ?? 0} haber çekildi${result['message'] != null ? '\n${result['message']}' : ''}'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')])))
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Test hatası: $e')))
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    // Basit düzenleme dialogu
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Kaynağı Sil'), content: Text('"${source.name}" kaynağı silinecek. Bu işlem geri alınamaz.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')), FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil'))]))
    if (confirmed == true) {
      await ref.read(sourceRepositoryProvider).deleteSource(source.id)
      ref.invalidate(sourcesProvider)
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kaynak silindi')))
    }
  }
}

class _SourceTileSkeleton extends StatelessWidget {
  final ThemeData theme
  const _SourceTileSkeleton({required this.theme})

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [_ShimmerBox(width: 44, height: 44, theme: theme), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_ShimmerBox(width: 120, height: 16, theme: theme), const SizedBox(height: 8), _ShimmerBox(width: 200, height: 12, theme: theme), const SizedBox(height: 8), _ShimmerBox(width: 150, height: 12, theme: theme)])]))))
}

class _Badge extends StatelessWidget {
  final String label
  final Color color
  const _Badge({required this.label, required this.color})
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)))
}

class _ShimmerBox extends StatefulWidget {
  final double width, height; final ThemeData theme
  const _ShimmerBox({required this.width, required this.height, required this.theme})
  @override State<_ShimmerBox> createState() => _ShimmerBoxState()
}
class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this)..repeat()
  @override void dispose() { _c.dispose(); super.dispose() }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, _) => Container(width: widget.width, height: widget.height, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), gradient: LinearGradient(begin: Alignment(-1.0 + _c.value * 2, 0), end: Alignment(1.0 + _c.value * 2, 0), colors: [widget.theme.colorScheme.surfaceContainerHighest, widget.theme.colorScheme.surfaceContainer, widget.theme.colorScheme.surfaceContainerHighest], stops: const [0.0, 0.5, 1.0]))))
}

// Sources Provider
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:riverpod_annotation/riverpod_annotation.dart'

import '../../../data/providers.dart'
import '../../../data/models/news_source.dart'

part 'sources_provider.g.dart'

@riverpod
class SourcesNotifier extends _$SourcesNotifier {
  @override
  Future<List<NewsSource>> build() async {
    return ref.read(sourceRepositoryProvider).getAllSources()
  }

  Future<void> loadSources() async {
    state = const AsyncLoading()
    state = await AsyncValue.guard(() => ref.read(sourceRepositoryProvider).getAllSources())
  }
}