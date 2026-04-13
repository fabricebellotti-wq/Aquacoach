import 'enums.dart';

/// Données d'une longueur / intervalle dans une séance
class SwimLap {
  const SwimLap({
    required this.lapNumber,
    required this.distanceMeters,
    required this.duration,
    required this.swolf,
    required this.heartRate,
    required this.strokeType,
    required this.strokeCount,
    this.pace,
  });

  final int lapNumber;
  final int distanceMeters;
  final Duration duration;

  /// SWOLF = nombre de coups + secondes pour 25m
  final double swolf;

  final int heartRate;
  final StrokeType strokeType;
  final int strokeCount;

  /// Allure en secondes / 100m
  final double? pace;

  @override
  String toString() =>
      'Lap $lapNumber — ${distanceMeters}m, SWOLF: $swolf, HR: ${heartRate}bpm';
}
