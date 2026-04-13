import 'enums.dart';

/// Métriques physiologiques actuelles de la montre
/// Certains champs sont exclusifs Garmin (bodyBattery, trainingLoad)
class WatchMetrics {
  const WatchMetrics({
    required this.source,
    required this.timestamp,
    this.bodyBattery,
    this.trainingLoad7d,
    this.trainingLoad28d,
    this.restingHeartRate,
    this.stressLevel,
    this.sleepScore,
    this.dailySteps,
  });

  final WatchSource source;
  final DateTime timestamp;

  /// Body Battery Garmin (0–100) — null si non Garmin
  final int? bodyBattery;

  /// Charge d'entraînement sur 7 jours — Garmin & Polar
  final double? trainingLoad7d;

  /// Charge d'entraînement sur 28 jours
  final double? trainingLoad28d;

  final int? restingHeartRate;
  final int? stressLevel;
  final int? sleepScore;
  final int? dailySteps;

  /// Indique si la séance doit être allégée (Body Battery < 60)
  bool get shouldReduceLoad =>
      bodyBattery != null && bodyBattery! < 60;

  /// Réduction de charge recommandée en % (20% si BB < 60)
  double get loadReductionFactor {
    if (!shouldReduceLoad) return 1.0;
    if (bodyBattery! < 40) return 0.7; // -30% si très bas
    return 0.8; // -20% standard
  }
}

/// Capacités disponibles selon la source montre
class WatchCapabilities {
  const WatchCapabilities({
    required this.source,
    required this.hasSwolf,
    required this.hasBodyBattery,
    required this.hasTrainingLoad,
    required this.hasOpenWaterGps,
    required this.hasLapHeartRate,
    required this.hasStrokeType,
  });

  final WatchSource source;
  final bool hasSwolf;
  final bool hasBodyBattery;    // Exclusif Garmin
  final bool hasTrainingLoad;
  final bool hasOpenWaterGps;
  final bool hasLapHeartRate;
  final bool hasStrokeType;

  static const garmin = WatchCapabilities(
    source: WatchSource.garmin,
    hasSwolf: true,
    hasBodyBattery: true,
    hasTrainingLoad: true,
    hasOpenWaterGps: true,
    hasLapHeartRate: true,
    hasStrokeType: true,
  );

  static const coros = WatchCapabilities(
    source: WatchSource.coros,
    hasSwolf: true,
    hasBodyBattery: false,
    hasTrainingLoad: true,
    hasOpenWaterGps: true,
    hasLapHeartRate: true,
    hasStrokeType: true,
  );

  static const apple = WatchCapabilities(
    source: WatchSource.apple,
    hasSwolf: false, // Calculé approximativement via HealthKit
    hasBodyBattery: false,
    hasTrainingLoad: false,
    hasOpenWaterGps: true,
    hasLapHeartRate: true,
    hasStrokeType: false,
  );
}
