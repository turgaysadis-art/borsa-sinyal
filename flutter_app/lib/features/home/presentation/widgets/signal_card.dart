// ==========================================
// BORSA SİNYAL FLUTTER - SIGNAL CARD
// ==========================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils.dart'
import '../../../../data/models/signal.dart'

class SignalCard extends StatelessWidget {
  final Signal? signal;
  final VoidCallback? onTap;

  const SignalCard({super.key, this.signal, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (signal == null) {
      return _EmptyCard(onTap: onTap);
    }

    final directionColor = signal.directionColor;
    final icon = signal.directionIcon;
    final label = signal.directionLabel;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                directionColor.withOpacity(0.15),
                directionColor.withOpacity(0.05),
              ],
            ),
            border: Border.all(color: directionColor.withOpacity(0.3), width: 1.5),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Başlık satırı
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: directionColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: directionColor, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Günlük Sinyal',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          DateFormat('d MMMM yyyy', 'tr_TR').format(signal.date.toLocal()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ConfidenceBadge(confidence: signal.confidence, color: directionColor),
                ],
              ),

              const SizedBox(height: 20),

              // Yön ve Güven
              Row(
                children: [
                  Text(
                    label,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: directionColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Güven: %${(signal.confidence * 100).round()}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: signal.confidence,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          backgroundColor: directionColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(directionColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Detay bileşenler
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _DetailChip(
                    icon: Icons.article_outlined,
                    label: '${signal.components['news_count'] ?? 0} haber',
                    color: theme.colorScheme.primary,
                  ),
                  _DetailChip(
                    icon: Icons.analytics_outlined,
                    label: 'Ağırlıklı: ${(signal.components['weighted_sentiment'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                    color: sentimentColor(
                      (signal.components['weighted_sentiment'] as num?)?.toDouble() ?? 0,
                    ),
                  ),
                  if (signal.components['ml_direction'] != null)
                    _DetailChip(
                      icon: Icons.psychology_outlined,
                      label: 'ML: ${signal.components['ml_direction']} (%${((signal.components['ml_confidence'] as num?)?.toDouble() ?? 0 * 100).round()})',
                      color: theme.colorScheme.secondary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _EmptyCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Henüz sinyal yok',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Yenileyerek bugünün sinyalini hesaplayın',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;
  final Color color;

  const _ConfidenceBadge({required this.confidence, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '%${(confidence * 100).round()}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}