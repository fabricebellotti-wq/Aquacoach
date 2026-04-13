import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/watch_metrics.dart';

/// Card Body Battery Garmin avec barre de progression et recommandation
class BodyBatteryCard extends StatelessWidget {
  const BodyBatteryCard({super.key, required this.metrics});

  final WatchMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final bb = metrics.bodyBattery;
    if (bb == null) return const SizedBox.shrink();

    final color = AppColors.bodyBatteryColor(bb);
    final recommendation = _recommendation(bb);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.battery_charging_full, color: color, size: 18),
                const SizedBox(width: 6),
                Text('Body Battery',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text(
                  '$bb / 100',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: bb / 100,
                minHeight: 8,
                backgroundColor: color.withAlpha(40),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  _recommendationIcon(bb),
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _recommendation(int bb) {
    if (bb >= 75) return 'Énergie optimale — séance intense possible';
    if (bb >= 60) return 'Bonne forme — séance normale recommandée';
    if (bb >= 40) return 'Fatigue modérée — charge réduite de 20%';
    return 'Fatigue élevée — séance de récupération uniquement';
  }

  IconData _recommendationIcon(int bb) {
    if (bb >= 60) return Icons.check_circle_outline;
    if (bb >= 40) return Icons.warning_amber_outlined;
    return Icons.bedtime_outlined;
  }
}
