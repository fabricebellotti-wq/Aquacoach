import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_watch_data_source.dart';
import '../../domain/repositories/watch_data_source.dart';
import '../../domain/models/swim_session.dart';
import '../../domain/models/watch_metrics.dart';

/// Provider de la source de données montre.
///
/// En phase MVP : MockWatchDataSource
/// Quand Garmin est confirmé : override avec GarminDataSource
///   runApp(ProviderScope(
///     overrides: [watchDataSourceProvider.overrideWithValue(GarminDataSource())],
///     child: const AquaCoachApp(),
///   ));
final watchDataSourceProvider = Provider<WatchDataSource>((ref) {
  return MockWatchDataSource();
});

/// Séances des 90 derniers jours
final sessionsProvider = FutureProvider<List<SwimSession>>((ref) async {
  final source = ref.watch(watchDataSourceProvider);
  return source.fetchSessions(
    since: DateTime.now().subtract(const Duration(days: 90)),
  );
});

/// Métriques actuelles (Body Battery, Training Load…)
final watchMetricsProvider = FutureProvider<WatchMetrics>((ref) async {
  final source = ref.watch(watchDataSourceProvider);
  return source.getMetrics();
});

/// Séances des 30 derniers jours pour le dashboard
final recentSessionsProvider = FutureProvider<List<SwimSession>>((ref) async {
  final sessions = await ref.watch(sessionsProvider.future);
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  return sessions.where((s) => s.startTime.isAfter(cutoff)).toList();
});
