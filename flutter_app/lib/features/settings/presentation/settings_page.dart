// ==========================================
// BORSA SİNYAL FLUTTER - SETTINGS PAGE
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:flutter_colorpicker/flutter_colorpicker.dart'
import 'package:url_launcher/url_launcher.dart'

import '../../../../core/theme/app_theme.dart'
import '../../../../core/storage/prefs_service.dart'
import '../../../../shared/widgets.dart'
import 'theme_selector.dart'
import 'backup_section.dart'

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsServiceProvider)

    return AppScaffold(
      title: 'Ayarlar',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- TEMA ---
          _SectionCard(
            title: 'Görünüm',
            icon: Icons.palette_outlined,
            children: [
              const ThemeSelector(),
              const SizedBox(height: 12),
              _CustomThemeBuilder(prefs: prefs),
            ],
          ),

          const SizedBox(height: 16),

          // --- VERİ YÖNETİMİ ---
          _SectionCard(
            title: 'Veri Yönetimi',
            icon: Icons.storage_outlined,
            children: [
              const BackupSection(),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Tüm Verileri Temizle'),
                subtitle: const Text('Haberler, sinyaller ve ayarlar silinir'),
                textColor: Colors.red,
                onTap: () => _confirmClearAll(context, prefs),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- BİLDİRİMLER ---
          _SectionCard(
            title: 'Bildirimler',
            icon: Icons.notifications_outlined,
            children: [
              SwitchListTile(
                title: const Text('Bildirimler Açık'),
                subtitle: const Text('Günlük sinyal ve önemli haber bildirimleri'),
                value: prefs.notificationsEnabled,
                onChanged: (v) => prefs.setNotificationsEnabled(v),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- GELİŞMİŞ ---
          _SectionCard(
            title: 'Gelişmiş',
            icon: Icons.developer_mode_outlined,
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Backend URL'),
                subtitle: Text(prefs.backendUrl),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _editBackendUrl(context, prefs),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Uygulama Sürümü'),
                subtitle: const Text('2.0.0'),
              ),
              ListTile(
                leading: const Icon(Icons.code_outlined),
                title: const Text('Açık Kaynak Lisanslar'),
                onTap: () => _showLicenses(context),
              ),
            ],
          ),
        ],
      ),
    )
  }

  Future<void> _confirmClearAll(BuildContext context, PrefsService prefs) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Tüm haberler, sinyaller ve ayarlar silinecektir. '
          'Önce yedek almanız önerilir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    )

    if (confirmed == true) {
      await prefs.clearAll()
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tüm veriler temizlendi')),
        )
      }
    }
  }

  Future<void> _editBackendUrl(BuildContext context, PrefsService prefs) async {
    final controller = TextEditingController(text: prefs.backendUrl)
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'http://10.0.2.2:8000/api/v1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Kaydet')),
        ],
      ),
    )

    if (result != null && result.isNotEmpty) {
      await prefs.setBackendUrl(result)
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(context: context, applicationName: 'Borsa Sinyal', applicationVersion: '2.0.0')
  }
}

class _SectionCard extends StatelessWidget {
  final String title
  final IconData icon
  final List<Widget> children

  const _SectionCard({
    required this.title
    required this.icon
    required this.children,
  })

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context)
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    )
  }
}

class _CustomThemeBuilder extends ConsumerWidget {
  final PrefsService prefs

  const _CustomThemeBuilder({required this.prefs})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (prefs.themeMode != 'custom') return const SizedBox.shrink()

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Text('Özel Tema Ayarları', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Ana Renk (Seed)',
          initialColor: prefs.customSeedColor ?? const Color(0xFF006B3C),
          onChanged: (c) => prefs.setCustomSeedColor(c),
        ),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Arka Plan (Light)',
          initialColor: prefs.customBgLight ?? const Color(0xFFF8F9FA),
          onChanged: (c) => prefs.setCustomBgLight(c),
        ),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Arka Plan (Dark)',
          initialColor: prefs.customBgDark ?? const Color(0xFF0A0A0A),
          onChanged: (c) => prefs.setCustomBgDark(c),
        ),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Kart/Yüzey (Light)',
          initialColor: prefs.customSurfaceLight ?? Colors.white,
          onChanged: (c) => prefs.setCustomSurfaceLight(c),
        ),
        const SizedBox(height: 12),
        _ColorPickerField(
          label: 'Kart/Yüzey (Dark)',
          initialColor: prefs.customSurfaceDark ?? const Color(0xFF1E1E1E),
          onChanged: (c) => prefs.setCustomSurfaceDark(c),
        ),
      ],
    )
  }
}

class _ColorPickerField extends StatelessWidget {
  final String label
  final Color initialColor
  final ValueChanged<Color> onChanged

  const _ColorPickerField({
    required this.label
    required this.initialColor
    required this.onChanged,
  })

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        GestureDetector(
          onTap: () async {
            final color = await showDialog<Color>(
              context: context,
              builder: (ctx) => _ColorPickerDialog(initialColor: initialColor),
            )
            if (color != null) onChanged(color)
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: initialColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    )
  }
}

class _ColorPickerDialog extends StatefulWidget {
  final Color initialColor

  const _ColorPickerDialog({required this.initialColor})

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState()
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor

  @override
  void initState() {
    super.initState()
    _selectedColor = widget.initialColor
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Renk Seç'),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _selectedColor,
          onColorChanged: (c) => setState(() => _selectedColor = c),
          enableAlpha: false,
          displayThumbColor: true,
          paletteType: PaletteType.hsv,
          pickerAreaHeightPercent: 0.7,
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
        FilledButton(onPressed: () => Navigator.pop(context, _selectedColor), child: const Text('Seç')),
      ],
    )
  }
}