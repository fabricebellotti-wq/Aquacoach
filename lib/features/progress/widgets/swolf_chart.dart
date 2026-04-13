import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/swim_session.dart';

/// Courbe SWOLF sur les N derniers jours
/// Plus le SWOLF est bas, meilleure est la technique → axe Y inversé visuellement
class SwolfChart extends StatelessWidget {
  const SwolfChart({super.key, required this.sessions, required this.days});

  final List<SwimSession> sessions;
  final int days; // 30 ou 90

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final filtered = sessions
        .where((s) => s.startTime.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (filtered.isEmpty) {
      return const _EmptyChart(message: 'Pas de données SWOLF');
    }

    final spots = filtered.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.averageSwolf);
    }).toList();

    final minY = (filtered.map((s) => s.averageSwolf).reduce((a, b) => a < b ? a : b) - 3).clamp(20.0, 80.0);
    final maxY = (filtered.map((s) => s.averageSwolf).reduce((a, b) => a > b ? a : b) + 3).clamp(20.0, 80.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 5,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.primary.withAlpha(20),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 5,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (filtered.length / 4).ceilToDouble().clamp(1, 999),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= filtered.length) return const SizedBox();
                final dt = filtered[idx].startTime;
                return Text(
                  '${dt.day}/${dt.month}',
                  style: const TextStyle(
                      fontSize: 9, color: AppColors.textSecondary),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minY,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.primaryDark,
            getTooltipItems: (spots) => spots.map((s) {
              final session = filtered[s.spotIndex];
              return LineTooltipItem(
                'SWOLF ${s.y.toStringAsFixed(1)}\n${session.startTime.day}/${session.startTime.month}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: FlDotData(
              show: spots.length <= 15,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 3,
                color: AppColors.primary,
                strokeWidth: 2,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(60),
                  AppColors.primary.withAlpha(0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Ligne de tendance
          if (spots.length >= 3) _trendLine(spots, minY, maxY),
        ],
      ),
    );
  }

  LineChartBarData _trendLine(List<FlSpot> spots, double minY, double maxY) {
    // Régression linéaire simple
    final n = spots.length;
    final sumX = spots.fold(0.0, (s, p) => s + p.x);
    final sumY = spots.fold(0.0, (s, p) => s + p.y);
    final sumXY = spots.fold(0.0, (s, p) => s + p.x * p.y);
    final sumX2 = spots.fold(0.0, (s, p) => s + p.x * p.x);
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    final first = FlSpot(spots.first.x, (slope * spots.first.x + intercept).clamp(minY, maxY));
    final last = FlSpot(spots.last.x, (slope * spots.last.x + intercept).clamp(minY, maxY));

    return LineChartBarData(
      spots: [first, last],
      isCurved: false,
      color: AppColors.accent.withAlpha(160),
      barWidth: 1.5,
      dashArray: [6, 4],
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: const TextStyle(color: AppColors.textHint, fontSize: 13)),
    );
  }
}
