import '../models/enums.dart';
import '../models/swim_session.dart';
import '../models/watch_metrics.dart';

/// Interface abstraite pour toute source de données montre.
///
/// La logique métier (plans, dashboard, progression) ne connaît QUE cette interface.
/// Les implémentations concrètes (Garmin, Coros, Apple, Mock) sont interchangeables.
///
/// Pattern : Repository + Strategy
abstract class WatchDataSource {
  /// Source identifiée
  WatchSource get source;

  /// Capacités disponibles pour cette source
  WatchCapabilities get capabilities;

  /// Lance le flux OAuth / authentification spécifique à la source.
  /// Retourne true si l'authentification a réussi.
  Future<bool> authenticate();

  /// Vérifie si l'utilisateur est déjà authentifié.
  Future<bool> isAuthenticated();

  /// Révoque l'accès et supprime les tokens locaux.
  Future<void> revokeAccess();

  /// Récupère les séances de natation depuis [since] (null = tout l'historique).
  /// Implémentations : filtrent sur POOL_SWIMMING et OPEN_WATER_SWIMMING.
  Future<List<SwimSession>> fetchSessions({DateTime? since});

  /// Retourne les métriques physiologiques actuelles (Body Battery, Training Load…).
  /// Les champs non disponibles pour la source seront null.
  Future<WatchMetrics> getMetrics();

  /// Force une synchronisation immédiate.
  Future<void> syncNow();

  /// Dernière date de synchronisation réussie.
  Future<DateTime?> getLastSyncTime();
}
