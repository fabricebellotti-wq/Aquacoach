import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/swim_session.dart';

/// Cartes de stats clés : SWOLF moyen, allure, volume, progression
class StatsSummary extends StatelessWidget {
  const StatsSummary({super.key, required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();

    final recent = sessions.take(5).toList();
    final older = sessions.length > 5 ? sessions.skip(5).take(5).toList() : <SwimSession>[];

    final avgSwolf = _avg(recent.map((s) => s.averageSwolf).toList());
    final prevSwolf = older.isEmpty ? null : _avg(older.map((s) => s.averageSwolf).toList());
    final swolfDelta = prevSwolf != null ? avgSwolf - prevSwolf : null;

    final avgPace = _avg(recent.map((s) => s.averagePace).toList());
    final totalVolume = sessions.fold(0, (s, e) => s + e.distanceMeters);
    final sessionsCount = sessions.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.6,
        children: [
          _StatCard(
            label: 'SWOLF moyen',
            value: avgSwolf.toStringAsFixed(1),
            icon: Icons.water_drop_outlined,
            delta: swolfDelta,
            deltaPositiveIsGood: false,
            subtitle: 'sur les 5 dernières',
          ),
          _StatCard(
            label: 'Allure moyenne',
            value: _fmtPace(avgPace),
            icon: Icons.speed_outlined,
            subtitle: '/100m',
          ),
          _StatCard(
            label: 'Volume total',
            value: totalVolume >= 1000
                ? '${(totalVolume / 1000).toStringAsFixed(1)} km'
                : '${totalVolume}m',
            icon: Icons.straighten_outlined,
            subtitle: 'sur 90 jours',
          ),
          _StatCard(
            label: 'Séances',
            value: '$sessionsCount',
            icon: Icons.calendar_today_outlined,
            subtitle: 'sur 90 jours',
          ),
        ],
      ),
    );
  }

  double _avg(List<double> values) =>
      values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

  String _fmtPace(double seconds) {
    final m = (seconds / 60).floor();
    final s = (seconds % 60).round();
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.delta,
    this.deltaPositiveIsGood = true,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final double? delta;
  final bool deltaPositiveIsGood;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final hasDelta = delta != null && delta != 0;
    final isGood = deltaPositiveIsGood ? (delta ?? 0) > 0 : (delta ?? 0) < 0;
    final deltaColor = isGood ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (hasDelta) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Icon(
                        isGood ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                        size: 16,
                        color: deltaColor,
                      ),
                      Text(
                        delta!.abs().toStringAsFixed(1),
                        style: TextStyle(fontSize: 11, color: deltaColor),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textHint)),
        ],
      ),
    );
  }
}
