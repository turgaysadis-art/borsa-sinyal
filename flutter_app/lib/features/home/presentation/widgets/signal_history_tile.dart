// ==========================================
// BORSA SİNYAL FLUTTER - SIGNAL HISTORY TILE
// ==========================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'

import '../../../../core/utils.dart'
import '../../../../data/models/signal.dart'

class SignalHistoryTile extends StatelessWidget {
  final Signal signal;
  final VoidCallback? onTap;

  const SignalHistoryTile({super.key, required this.signal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final directionColor = signal.directionColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: directionColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(signal.directionIcon, color: directionColor, size: 20),
      ),
      title: Text(
        signal.directionLabel,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: directionColor,
        ),
      ),
      subtitle: Text(
        DateFormat('d MMMM yyyy', 'tr_TR').format(signal.date.toLocal()),
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '%${(signal.confidence * 100).round()}',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: directionColor,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: directionColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              signal.direction == 'UP' ? '▲' : (signal.direction == 'DOWN' ? '▼' : '●'),
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: directionColor),
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}