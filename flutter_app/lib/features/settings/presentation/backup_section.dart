// ==========================================
// BORSA SİNYAL FLUTTER - BACKUP SECTION
// ==========================================
import 'dart:convert'
import 'dart:io'

import 'package:flutter/material.dart'
import 'package:flutter_riverpod/flutter_riverpod.dart'
import 'package:file_picker/file_picker.dart'
import 'package:permission_handler/permission_handler.dart'
import 'package:share_plus/share_plus.dart'

import '../../../../core/storage/isar_service.dart'
import '../../../../core/storage/prefs_service.dart'
import '../../../../data/providers.dart'
import '../../../../shared/widgets.dart'

class BackupSection extends ConsumerWidget {
  const BackupSection({super.key})

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Yedek Al (JSON)'),
          subtitle: const Text('Tüm verileri JSON dosyası olarak dışa aktar'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _exportData(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Yedek Yükle (JSON)'),
          subtitle: const Text('Önceden alınmış yedeği içe aktar'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _importData(context, ref),
        ),
      ],
    )
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final isarService = ref.read(isarProvider)
    
    // Tüm verileri çek
    final sources = await isarService.newsSources.where().findAll()
    final signals = await isarService.signals.where().findAll()
    final settings = await isarService.appSettings.where().findFirst()
    
    // Haberleri de çek (son 1000)
    final news = await isarService.newsItems
        .where()
        .sortByFetchedAtDesc()
        .limit(1000)
        .findAll()
    
    final exportData = {
      'version': '2.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'sources': sources.map((s) => s.toJson()).toList(),
      'signals': signals.map((s) => s.toJson()).toList(),
      'news': news.map((n) => n.toJson()).toList(),
      'settings': settings?.toJson(),
    }
    
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData)
    
    // Dosya paylaş
    await Share.shareXFiles([
      XFile.fromData(
        utf8.encode(jsonString),
        name: 'borsa_sinyal_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json',
        mimeType: 'application/json',
      ),
    ], text: 'Borsa Sinyal Yedeği')
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    )
    
    if (result == null || result.files.isEmpty) return
    
    final file = result.files.first
    if (file.bytes == null) return
    
    try {
      final jsonString = utf8.decode(file.bytes!)
      final data = jsonDecode(jsonString) as Map<String, dynamic>
      
      // Versiyon kontrolü
      if (data['version'] != '2.0.0') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yedek dosyası uyumsuz versiyon')),
          )
        }
        return
      }
      
      final isarService = ref.read(isarService)
      
      // Verileri içe aktar
      await isarService.writeTxn(() async {
        // Kaynaklar
        if (data['sources'] != null) {
          for (final src in data['sources']) {
            final source = NewsSource.fromJson(src)
            await isarService.newsSources.put(source)
          }
        }
        
        // Sinyaller
        if (data['signals'] != null) {
          for (final sig in data['signals']) {
            final signal = Signal.fromJson(sig)
            await isarService.signals.put(signal)
          }
        }
        
        // Haberler
        if (data['news'] != null) {
          for (final n in data['news']) {
            final news = NewsItem.fromJson(n)
            await isarService.newsItems.put(news)
          }
        }
        
        // Ayarlar
        if (data['settings'] != null) {
          final settings = AppSettings.fromJson(data['settings'])
          await isarService.appSettings.put(settings)
        }
      })
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek başarıyla yüklendi')),
        )
        ref.invalidate(latestSignalProvider)
        ref.invalidate(signalsProvider(SignalsQuery(limit: 20)))
        ref.invalidate(latestNewsProvider(20))
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek yüklenemedi: $e')),
        )
      }
    }
  }
}