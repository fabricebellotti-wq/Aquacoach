import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/training_block.dart';
import '../../../domain/models/training_session.dart';

/// Card séance du jour avec résumé des blocs et bouton démarrer
class TodaySessionCard extends StatelessWidget {
  const TodaySessionCard({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _sessionTypeLabel(session),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${session.totalDistanceMeters}m',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Durée estimée : ${_formatDuration(session.estimatedDuration)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),

            // Blocs
            ...session.blocks.map((b) => _BlockRow(block: b)),

            const SizedBox(height: 16),

            // Bouton démarrer
            FilledButton.icon(
              onPressed: () {
                // TODO: naviguer vers la séance guidée
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer la séance'),
            ),
          ],
        ),
      ),
    );
  }

  String _sessionTypeLabel(TrainingSession s) {
    if (s.blocks.isEmpty) return 'Repos';
    final mainBlock = s.blocks.firstWhere(
      (b) => b.type == BlockType.main || b.type == BlockType.threshold,
      orElse: () => s.blocks.first,
    );
    return switch (mainBlock.type) {
      BlockType.threshold => 'Séance Seuil',
      BlockType.recovery => 'Récupération',
      _ => 'Endurance',
    };
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    return '${m}min';
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block});

  final TrainingBlock block;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: _blockColor(block.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  block.summary,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${block.totalDistance}m',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _blockColor(BlockType type) => switch (type) {
        BlockType.warmup => AppColors.accent,
        BlockType.drill => AppColors.warning,
        BlockType.main => AppColors.primary,
        BlockType.threshold => const Color(0xFFE63946),
        BlockType.recovery => AppColors.success,
        BlockType.cooldown => AppColors.primaryLight,
      };
}
