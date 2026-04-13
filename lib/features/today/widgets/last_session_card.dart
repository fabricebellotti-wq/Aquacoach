import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/swim_session.dart';

/// Card résumé de la dernière séance importée depuis la montre
class LastSessionCard extends StatelessWidget {
  const LastSessionCard({
    super.key,
    required this.session,
    this.previousSession,
  });

  final SwimSession session;

  /// Pour calculer le delta SWOLF
  final SwimSession? previousSession;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swolfDelta = previousSession != null
        ? session.averageSwolf - previousSession!.averageSwolf
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sync, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Dernière séance — ${_formatDate(session.startTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _MetricTile(
                  label: 'Distance',
                  value: session.formattedDistance,
                  icon: Icons.straighten,
                ),
                _MetricTile(
                  label: 'Durée',
                  value: _formatDuration(session.duration),
                  icon: Icons.timer_outlined,
                ),
                _MetricTile(
                  label: 'SWOLF',
                  value: session.averageSwolf.toStringAsFixed(1),
                  icon: Icons.water_drop_outlined,
                  delta: swolfDelta,
                  // SWOLF : plus bas = mieux, donc delta négatif = positif
                  deltaPositiveIsGood: false,
                ),
                _MetricTile(
                  label: 'Allure',
                  value: session.formattedPace,
                  icon: Icons.speed_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return "aujourd'hui";
    if (diff == 1) return 'hier';
    if (diff < 7) return 'il y a $diff jours';
    return '${dt.day}/${dt.month}';
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    return '$m\'${s.toString().padLeft(2, '0')}"';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.delta,
    this.deltaPositiveIsGood = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final double? delta;
  final bool deltaPositiveIsGood;

  @override
  Widget build(BuildContext context) {
    final hasDelta = delta != null && delta != 0;
    final isGoodDelta = deltaPositiveIsGood ? (delta ?? 0) > 0 : (delta ?? 0) < 0;
    final deltaColor = isGoodDelta ? AppColors.success : AppColors.error;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasDelta) ...[
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isGoodDelta ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                  size: 14,
                  color: deltaColor,
                ),
                Text(
                  delta!.abs().toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: deltaColor),
                ),
              ],
            ),
          ],
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
