import 'enums.dart';
import 'swim_lap.dart';

/// Séance de natation normalisée — indépendante de la source (Garmin/Coros/Apple)
class SwimSession {
  const SwimSession({
    required this.id,
    required this.startTime,
    required this.duration,
    required this.distanceMeters,
    required this.averagePace,
    required this.averageSwolf,
    required this.averageHeartRate,
    required this.maxHeartRate,
    required this.laps,
    required this.type,
    required this.source,
    this.bodyBatteryStart,
    this.bodyBatteryEnd,
    this.trainingLoad,
    this.poolLength,
    this.calories,
    this.notes,
  });

  final String id;
  final DateTime startTime;
  final Duration duration;
  final int distanceMeters;

  /// Allure moyenne en secondes / 100m
  final double averagePace;

  /// SWOLF moyen sur la séance
  final double averageSwolf;

  final int averageHeartRate;
  final int maxHeartRate;
  final List<SwimLap> laps;
  final ActivityType type;
  final WatchSource source;

  /// Body Battery Garmin au début de la séance (0–100), null si non disponible
  final int? bodyBatteryStart;

  /// Body Battery Garmin à la fin de la séance
  final int? bodyBatteryEnd;

  /// Charge d'entraînement Garmin
  final double? trainingLoad;

  /// Longueur du bassin en mètres (25 ou 50), null pour eau libre
  final int? poolLength;

  final int? calories;
  final String? notes;

  /// Formatage de l'allure en mm:ss/100m
  String get formattedPace {
    final minutes = (averagePace / 60).floor();
    final seconds = (averagePace % 60).round();
    return "$minutes'${seconds.toString().padLeft(2, '0')}\"/100m"; // ignore: unnecessary_brace_in_string_interps
  }

  /// Distance formatée (ex: 2,400m ou 2.4km)
  String get formattedDistance {
    if (distanceMeters >= 1000) {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceMeters}m';
  }

  @override
  String toString() =>
      'SwimSession[$id] ${startTime.toLocal()} — $formattedDistance, SWOLF: $averageSwolf, $source';
}
