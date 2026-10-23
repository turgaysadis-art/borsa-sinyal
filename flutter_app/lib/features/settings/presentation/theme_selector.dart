// ==========================================
// BORSA SİNYAL FLUTTER - THEME SELECTOR
// ==========================================
import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'

import '../../../../core/theme/app_theme.dart'
import '../../../../core/storage/prefs_service.dart'

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prefsServiceProvider)
    final currentTheme = prefs.themeMode

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tema Modu', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'system', label: Text('Sistem'), icon: Icon(Icons.brightness_auto)),
            ButtonSegment(value: 'light', label: Text('Açık'), icon: Icon(Icons.light_mode)),
            ButtonSegment(value: 'dark', label: Text('Koyu'), icon: Icon(Icons.dark_mode)),
            ButtonSegment(value: 'custom', label: Text('Özel'), icon: Icon(Icons.color_lens)),
          ],
          selected: {currentTheme},
          onSelectionChange: (Set<String> selection) {
            prefs.setThemeMode(selection.first)
          },
          showSelectedIcon: false,
        ),
      ],
    )
  }
}