import 'enums.dart';
import 'training_block.dart';

/// Séance planifiée dans le plan hebdomadaire
class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.scheduledDate,
    required this.blocks,
    required this.status,
    this.completedSessionId,
    this.notes,
  });

  final String id;
  final DateTime scheduledDate;
  final List<TrainingBlock> blocks;
  final SessionStatus status;

  /// ID de la SwimSession réalisée (lien avec l'import montre)
  final String? completedSessionId;

  final String? notes;

  /// Distance totale prévue
  int get totalDistanceMeters =>
      blocks.fold(0, (sum, b) => sum + b.totalDistance);

  /// Durée estimée (distance / allure approximative selon intensité)
  Duration get estimatedDuration {
    final totalMeters = totalDistanceMeters;
    // ~2min/100m en moyenne + récup
    final swimMinutes = (totalMeters / 100) * 2.0;
    final restMinutes = blocks
        .where((b) => b.restDuration != null)
        .fold(0.0, (sum, b) => sum + (b.repetitions * b.restDuration!.inSeconds / 60));
    return Duration(minutes: (swimMinutes + restMinutes).round());
  }

  /// Label du jour (Lundi, Mardi, etc.)
  String get dayLabel {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[scheduledDate.weekday - 1];
  }

  bool get isToday {
    final now = DateTime.now();
    return scheduledDate.year == now.year &&
        scheduledDate.month == now.month &&
        scheduledDate.day == now.day;
  }

  TrainingSession copyWith({SessionStatus? status, String? completedSessionId}) {
    return TrainingSession(
      id: id,
      scheduledDate: scheduledDate,
      blocks: blocks,
      status: status ?? this.status,
      completedSessionId: completedSessionId ?? this.completedSessionId,
      notes: notes,
    );
  }
}
