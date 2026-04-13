import 'dart:math';

import '../../domain/models/enums.dart';
import '../../domain/models/swim_lap.dart';
import '../../domain/models/swim_session.dart';
import '../../domain/models/watch_metrics.dart';
import '../../domain/repositories/watch_data_source.dart';

/// Source de données bouchonnée — simule un utilisateur Garmin intermédiaire.
///
/// À utiliser pendant la phase MVP tant que le partenariat Garmin n'est pas confirmé.
/// Toutes les données sont réalistes (SWOLF 42–55, allure 1:45–2:30/100m).
///
/// Pour swapper vers la vraie implémentation Garmin :
///   ref.override(watchDataSourceProvider.overrideWithValue(GarminDataSource()))
class MockWatchDataSource implements WatchDataSource {
  MockWatchDataSource({this.simulatedBodyBattery = 72});

  /// Permet de simuler différents niveaux de Body Battery pour tester les ajustements
  final int simulatedBodyBattery;

  final _random = Random(42); // seed fixe pour des données reproductibles
  bool _authenticated = false;
  DateTime? _lastSync;

  @override
  WatchSource get source => WatchSource.garmin;

  @override
  WatchCapabilities get capabilities => WatchCapabilities.garmin;

  @override
  Future<bool> authenticate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    _authenticated = true;
    return true;
  }

  @override
  Future<bool> isAuthenticated() async => _authenticated;

  @override
  Future<void> revokeAccess() async {
    _authenticated = false;
    _lastSync = null;
  }

  @override
  Future<List<SwimSession>> fetchSessions({DateTime? since}) async {
    await Future.delayed(const Duration(milliseconds: 600));

    final cutoff = since ?? DateTime.now().subtract(const Duration(days: 90));
    return _generateSessions(cutoff);
  }

  @override
  Future<WatchMetrics> getMetrics() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return WatchMetrics(
      source: WatchSource.garmin,
      timestamp: DateTime.now(),
      bodyBattery: simulatedBodyBattery,
      trainingLoad7d: 38.5,
      trainingLoad28d: 142.0,
      restingHeartRate: 52,
      stressLevel: 24,
      sleepScore: 78,
      dailySteps: 7840,
    );
  }

  @override
  Future<void> syncNow() async {
    await Future.delayed(const Duration(seconds: 1));
    _lastSync = DateTime.now();
  }

  @override
  Future<DateTime?> getLastSyncTime() async => _lastSync;

  // ── Génération de séances réalistes ──────────────────────────────────────

  List<SwimSession> _generateSessions(DateTime since) {
    final sessions = <SwimSession>[];
    var current = DateTime.now().subtract(const Duration(days: 1));

    // ~3 séances/semaine sur les 90 derniers jours = ~38 séances
    while (current.isAfter(since)) {
      // Séances les lundi, mercredi, vendredi
      if (current.weekday == 1 ||
          current.weekday == 3 ||
          current.weekday == 5) {
        sessions.add(_generateSession(current));
      }
      current = current.subtract(const Duration(days: 1));
    }

    return sessions..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  SwimSession _generateSession(DateTime date) {
    // Progression légère du SWOLF sur 90 jours (amélioration simulée)
    final daysAgo = DateTime.now().difference(date).inDays;
    final progressFactor = 1 - (daysAgo / 90) * 0.08; // -8% sur 90j

    final baseSwolf = 48.0 * progressFactor;
    final swolfVariance = (_random.nextDouble() - 0.5) * 4;
    final sessionSwolf = (baseSwolf + swolfVariance).clamp(35.0, 65.0);

    final distance = [1500, 1800, 2000, 2400, 2500][_random.nextInt(5)];
    final lapCount = distance ~/ 50;

    final laps = List.generate(lapCount, (i) => _generateLap(i + 1, sessionSwolf));

    final avgPace = 105.0 + (_random.nextDouble() - 0.5) * 20; // ~1:45/100m
    final durationSecs = (distance / 100 * avgPace).round();

    return SwimSession(
      id: 'mock_${date.millisecondsSinceEpoch}',
      startTime: date.copyWith(hour: 7, minute: 0),
      duration: Duration(seconds: durationSecs),
      distanceMeters: distance,
      averagePace: avgPace,
      averageSwolf: double.parse(sessionSwolf.toStringAsFixed(1)),
      averageHeartRate: 145 + _random.nextInt(15),
      maxHeartRate: 168 + _random.nextInt(10),
      laps: laps,
      type: ActivityType.pool,
      source: WatchSource.garmin,
      bodyBatteryStart: simulatedBodyBattery + _random.nextInt(10),
      bodyBatteryEnd: simulatedBodyBattery - 15 - _random.nextInt(10),
      trainingLoad: 28.0 + _random.nextDouble() * 15,
      poolLength: 50,
      calories: (distance * 0.4 + _random.nextInt(30)).round(),
    );
  }

  SwimLap _generateLap(int number, double baseSwolf) {
    final swolf = baseSwolf + (_random.nextDouble() - 0.5) * 3;
    final duration = Duration(seconds: 45 + _random.nextInt(15));
    return SwimLap(
      lapNumber: number,
      distanceMeters: 50,
      duration: duration,
      swolf: double.parse(swolf.toStringAsFixed(1)),
      heartRate: 140 + _random.nextInt(20),
      strokeType: StrokeType.freestyle,
      strokeCount: (swolf - duration.inSeconds).round().clamp(15, 30),
      pace: (duration.inSeconds / 50 * 100).roundToDouble(),
    );
  }
}

extension on DateTime {
  DateTime copyWith({int? hour, int? minute, int? second}) => DateTime(
        year,
        month,
        day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
      );
}
