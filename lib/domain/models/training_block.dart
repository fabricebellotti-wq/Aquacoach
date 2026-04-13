import 'enums.dart';

/// Bloc d'une séance d'entraînement (échauffement, série principale, etc.)
class TrainingBlock {
  const TrainingBlock({
    required this.name,
    required this.type,
    required this.repetitions,
    required this.distanceMeters,
    required this.description,
    required this.intensity,
    this.restDuration,
    this.strokeType,
    this.notes,
  });

  final String name;
  final BlockType type;

  /// Nombre de répétitions (ex: 4x100m → repetitions = 4, distanceMeters = 100)
  final int repetitions;

  final int distanceMeters;
  final String description;
  final Intensity intensity;

  /// Temps de récupération entre les répétitions
  final Duration? restDuration;

  final StrokeType? strokeType;
  final String? notes;

  /// Distance totale du bloc
  int get totalDistance => repetitions * distanceMeters;

  /// Résumé lisible : "4×100m crawl — récup 20s"
  String get summary {
    final rest = restDuration != null
        ? ' — récup ${restDuration!.inSeconds}s'
        : '';
    final stroke =
        strokeType != null && strokeType != StrokeType.unknown && strokeType != StrokeType.mixed
            ? ' ${_strokeLabel(strokeType!)}'
            : '';
    return '$repetitions×${distanceMeters}m$stroke$rest';
  }

  String _strokeLabel(StrokeType s) => switch (s) {
        StrokeType.freestyle => 'crawl',
        StrokeType.backstroke => 'dos',
        StrokeType.breaststroke => 'brasse',
        StrokeType.butterfly => 'papillon',
        _ => '',
      };
}
