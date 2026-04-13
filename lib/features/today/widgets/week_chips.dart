import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/training_plan.dart';
import '../../../domain/models/training_session.dart';

/// Chips de la semaine — 7 jours avec statut visuel
class WeekChips extends StatelessWidget {
  const WeekChips({super.key, required this.plan});

  final TrainingPlan plan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: plan.sessions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final session = plan.sessions[index];
          return _DayChip(session: session);
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.session});

  final TrainingSession session;

  @override
  Widget build(BuildContext context) {
    final isRest = session.status == SessionStatus.rest;
    final isToday = session.isToday;
    final isDone = session.status == SessionStatus.completed;
    final isSkipped = session.status == SessionStatus.skipped;

    Color bg;
    Color border;
    Color textColor;
    Widget? icon;

    if (isToday) {
      bg = AppColors.primary;
      border = AppColors.primary;
      textColor = Colors.white;
    } else if (isDone) {
      bg = AppColors.success.withAlpha(30);
      border = AppColors.success;
      textColor = AppColors.success;
      icon = const Icon(Icons.check, size: 12, color: AppColors.success);
    } else if (isSkipped) {
      bg = AppColors.error.withAlpha(20);
      border = AppColors.error.withAlpha(80);
      textColor = AppColors.textHint;
    } else if (isRest) {
      bg = Colors.transparent;
      border = const Color(0xFFDDE7F3);
      textColor = AppColors.textHint;
    } else {
      // Planifiée future
      bg = AppColors.cardLight;
      border = const Color(0xFFDDE7F3);
      textColor = AppColors.textSecondary;
    }

    return Container(
      width: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ?icon,
          Text(
            session.dayLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: textColor,
            ),
          ),
          if (!isRest)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: isToday ? Colors.white70 : border,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
