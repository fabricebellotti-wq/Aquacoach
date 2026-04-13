import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/enums.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/services/training_plan_generator.dart';
import 'watch_provider.dart';

final _generator = const TrainingPlanGenerator();

/// Plan de la semaine courante
final currentWeekPlanProvider = FutureProvider<TrainingPlan>((ref) async {
  final metricsAsync = ref.watch(watchMetricsProvider);
  final metrics = metricsAsync.valueOrNull;

  // Lundi de la semaine courante
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final weekStart = DateTime(monday.year, monday.month, monday.day);

  // TODO: remplacer par le vrai profil utilisateur depuis Firestore
  return _generator.generateWeek(
    weekStart: weekStart,
    sessionsPerWeek: 3,
    level: SwimLevel.intermediate,
    goal: SwimGoal.poolProgression,
    metrics: metrics,
  );
});
