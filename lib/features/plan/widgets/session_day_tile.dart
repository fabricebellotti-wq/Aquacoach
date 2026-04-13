import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/training_block.dart';
import '../../../domain/models/training_session.dart';

/// Tile d'un jour dans la vue hebdomadaire du plan
class SessionDayTile extends StatelessWidget {
  const SessionDayTile({super.key, required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final isRest = session.status == SessionStatus.rest;
    final isToday = session.isToday;

    if (isRest) return _RestTile(session: session, isToday: isToday);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppColors.primary : const Color(0xFFDDE7F3),
          width: isToday ? 2 : 1,
        ),
        boxShadow: isToday
            ? [
                BoxShadow(
                  color: AppColors.primary.withAlpha(30),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: naviguer vers le détail de séance
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête jour + statut
                Row(
                  children: [
                    _DayBadge(session: session, isToday: isToday),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sessionTitle(session),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${session.totalDistanceMeters}m · ${_fmtDuration(session.estimatedDuration)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(status: session.status, isToday: isToday),
                  ],
                ),

                // Aperçu des blocs (mini barres colorées)
                if (session.blocks.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _BlocksPreview(blocks: session.blocks),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sessionTitle(TrainingSession s) {
    if (s.blocks.isEmpty) return 'Séance';
    final main = s.blocks.firstWhere(
      (b) => b.type == BlockType.main || b.type == BlockType.threshold,
      orElse: () => s.blocks.first,
    );
    return switch (main.type) {
      BlockType.threshold => 'Séance Seuil',
      BlockType.recovery => 'Récupération active',
      _ => 'Endurance fondamentale',
    };
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    return '$m min';
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.session, required this.isToday});

  final TrainingSession session;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final label = days[session.scheduledDate.weekday - 1];
    final day = session.scheduledDate.day;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isToday ? AppColors.primary : AppColors.cardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : AppColors.textSecondary,
            ),
          ),
          Text(
            '$day',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isToday});

  final SessionStatus status;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    if (status == SessionStatus.completed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 12, color: AppColors.success),
            SizedBox(width: 3),
            Text('Fait', style: TextStyle(fontSize: 11, color: AppColors.success)),
          ],
        ),
      );
    }
    if (isToday) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Aujourd'hui",
          style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (status == SessionStatus.skipped) {
      return const Icon(Icons.remove_circle_outline,
          size: 18, color: AppColors.textHint);
    }
    return const Icon(Icons.chevron_right, color: AppColors.textHint);
  }
}

class _BlocksPreview extends StatelessWidget {
  const _BlocksPreview({required this.blocks});

  final List<TrainingBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: blocks.map((b) {
        final flex = (b.totalDistance / 50).round().clamp(1, 20);
        return Expanded(
          flex: flex,
          child: Tooltip(
            message: '${b.name} · ${b.totalDistance}m',
            child: Container(
              height: 5,
              margin: const EdgeInsets.only(right: 2),
              decoration: BoxDecoration(
                color: _blockColor(b.type),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        );
      }).toList(),
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

class _RestTile extends StatelessWidget {
  const _RestTile({required this.session, required this.isToday});

  final TrainingSession session;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final label = days[session.scheduledDate.weekday - 1];
    final day = session.scheduledDate.day;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primary.withAlpha(80)
              : const Color(0xFFEEF4FB),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint)),
                Text('$day',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.bedtime_outlined, size: 16, color: AppColors.textHint),
          const SizedBox(width: 6),
          const Text('Repos',
              style: TextStyle(fontSize: 14, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
