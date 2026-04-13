import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/swim_session.dart';

/// Histogramme du volume mensuel (mètres nagés par semaine)
class VolumeChart extends StatelessWidget {
  const VolumeChart({super.key, required this.sessions});

  final List<SwimSession> sessions;

  @override
  Widget build(BuildContext context) {
    final weeklyVolume = _aggregateByWeek(sessions);
    if (weeklyVolume.isEmpty) {
      return const Center(
        child: Text('Pas de données de volume',
            style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      );
    }

    final maxY =
        weeklyVolume.values.reduce((a, b) => a > b ? a : b).toDouble();

    final barGroups = weeklyVolume.entries.toList().asMap().entries.map((e) {
      final index = e.key;
      final volume = e.value.value;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: volume.toDouble(),
            color: AppColors.primary,
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY * 1.1,
              color: AppColors.primary.withAlpha(15),
            ),
          ),
        ],
      );
    }).toList();

    final weekLabels = weeklyVolume.keys.toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.primary.withAlpha(20),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= weekLabels.length) {
                  return const SizedBox();
                }
                return Text(
                  weekLabels[idx],
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1000,
              getTitlesWidget: (value, meta) => Text(
                value >= 1000
                    ? '${(value / 1000).toStringAsFixed(1)}k'
                    : value.toInt().toString(),
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textSecondary),
              ),
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final meters = rod.toY.toInt();
              final label = weekLabels[groupIndex];
              return BarTooltipItem(
                '$label\n${meters}m',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  /// Agrège les séances par semaine ISO → Map<"S15", totalMeters>
  Map<String, int> _aggregateByWeek(List<SwimSession> sessions) {
    final map = <String, int>{};
    final cutoff = DateTime.now().subtract(const Duration(days: 90));

    for (final s in sessions) {
      if (s.startTime.isBefore(cutoff)) continue;
      final key = 'S${_weekNumber(s.startTime)}';
      map[key] = (map[key] ?? 0) + s.distanceMeters;
    }
    // Tri chronologique
    final sorted = Map.fromEntries(
      map.entries.toList()..sort((a, b) {
        final wa = int.tryParse(a.key.substring(1)) ?? 0;
        final wb = int.tryParse(b.key.substring(1)) ?? 0;
        return wa.compareTo(wb);
      }),
    );
    return sorted;
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }
}
