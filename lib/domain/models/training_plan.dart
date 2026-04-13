import 'enums.dart';
import 'training_session.dart';

/// Plan d'entraînement hebdomadaire — stocké dans Firestore users/{userId}/plans/{weekId}
class TrainingPlan {
  const TrainingPlan({
    required this.weekId,
    required this.sessions,
    required this.generatedAt,
    this.adjustmentReason,
  });

  /// Format ISO : "2026-W16"
  final String weekId;

  final List<TrainingSession> sessions;
  final DateTime generatedAt;

  /// Raison d'un éventuel ajustement automatique (ex: "Body Battery faible")
  final String? adjustmentReason;

  /// Distance totale prévue sur la semaine
  int get totalDistanceMeters =>
      sessions.fold(0, (sum, s) => sum + s.totalDistanceMeters);

  /// Distance déjà réalisée
  int get completedDistanceMeters => sessions
      .where((s) => s.status == SessionStatus.completed)
      .fold(0, (sum, s) => sum + s.totalDistanceMeters);

  /// Progression en % (0.0 → 1.0)
  double get weekProgress {
    if (totalDistanceMeters == 0) return 0;
    return completedDistanceMeters / totalDistanceMeters;
  }

  /// Séances non-repos
  List<TrainingSession> get trainingSessions =>
      sessions.where((s) => s.status != SessionStatus.rest).toList();

  /// Séance du jour (null si repos ou non trouvée)
  TrainingSession? get todaySession {
    try {
      return sessions.firstWhere((s) => s.isToday);
    } catch (_) {
      return null;
    }
  }

  /// Génère le weekId ISO depuis une date
  static String weekIdFromDate(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final weekNumber = _isoWeekNumber(monday);
    return '${monday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  static int _isoWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final firstMonday = startOfYear.weekday <= 4
        ? startOfYear.subtract(Duration(days: startOfYear.weekday - 1))
        : startOfYear.add(Duration(days: 8 - startOfYear.weekday));
    return ((date.difference(firstMonday).inDays) / 7).floor() + 1;
  }
}
