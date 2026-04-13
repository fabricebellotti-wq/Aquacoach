import '../models/enums.dart';
import '../models/swim_session.dart';
import '../models/training_block.dart';
import '../models/training_plan.dart';
import '../models/training_session.dart';
import '../models/watch_metrics.dart';

/// Génère le plan hebdomadaire côté client — zéro serveur (specs F03).
///
/// Logique de périodisation en blocs :
///   - Semaine type : Endurance / Seuil / Récupération / Endurance / Seuil
///   - Ajustement automatique si Body Battery < 60 (réduction 20%)
class TrainingPlanGenerator {
  const TrainingPlanGenerator();

  TrainingPlan generateWeek({
    required DateTime weekStart, // Lundi de la semaine
    required int sessionsPerWeek, // 3, 4 ou 5
    required SwimLevel level,
    required SwimGoal goal,
    WatchMetrics? metrics,
    List<SwimSession> recentSessions = const [],
  }) {
    final weekId = TrainingPlan.weekIdFromDate(weekStart);

    // Facteur de charge si Body Battery faible
    final loadFactor = metrics?.loadReductionFactor ?? 1.0;
    String? adjustmentReason;
    if (loadFactor < 1.0) {
      final bb = metrics!.bodyBattery!;
      adjustmentReason =
          'Body Battery faible ($bb/100) — charge réduite de ${((1 - loadFactor) * 100).round()}%';
    }

    // Sélection des jours de séance selon la fréquence
    final sessionDays = _selectDays(sessionsPerWeek);

    // Séquence de types selon le profil
    final sessionTypes = _buildSequence(sessionsPerWeek, goal);

    final sessions = <TrainingSession>[];
    for (var i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayIndex = sessionDays.indexOf(i);

      if (dayIndex == -1) {
        // Jour de repos
        sessions.add(TrainingSession(
          id: '${weekId}_d$i',
          scheduledDate: day,
          blocks: const [],
          status: SessionStatus.rest,
        ));
      } else {
        final type = sessionTypes[dayIndex];
        final baseDistance = _baseDistance(level);
        final adjustedDistance = (baseDistance * loadFactor).round();

        sessions.add(TrainingSession(
          id: '${weekId}_d$i',
          scheduledDate: day,
          blocks: _buildBlocks(type, adjustedDistance, level),
          status: SessionStatus.planned,
        ));
      }
    }

    return TrainingPlan(
      weekId: weekId,
      sessions: sessions,
      generatedAt: DateTime.now(),
      adjustmentReason: adjustmentReason,
    );
  }

  // ── Sélection des jours (0=lundi … 6=dimanche) ───────────────────────────

  List<int> _selectDays(int count) => switch (count) {
        3 => [0, 2, 4],       // Lun / Mer / Ven
        4 => [0, 2, 4, 6],    // Lun / Mer / Ven / Dim
        5 => [0, 1, 3, 4, 6], // Lun / Mar / Jeu / Ven / Dim
        _ => [0, 2, 4],
      };

  // ── Séquence des types de séance ─────────────────────────────────────────

  List<_SessionType> _buildSequence(int count, SwimGoal goal) {
    if (goal == SwimGoal.triathlonPrep || goal == SwimGoal.competition) {
      return switch (count) {
        3 => [_SessionType.endurance, _SessionType.threshold, _SessionType.endurance],
        4 => [_SessionType.endurance, _SessionType.threshold, _SessionType.endurance, _SessionType.recovery],
        _ => [_SessionType.endurance, _SessionType.threshold, _SessionType.recovery, _SessionType.threshold, _SessionType.endurance],
      };
    }
    // Fitness / progression standard
    return switch (count) {
      3 => [_SessionType.endurance, _SessionType.threshold, _SessionType.recovery],
      4 => [_SessionType.endurance, _SessionType.threshold, _SessionType.endurance, _SessionType.recovery],
      _ => [_SessionType.endurance, _SessionType.threshold, _SessionType.endurance, _SessionType.threshold, _SessionType.recovery],
    };
  }

  // ── Distance de base selon le niveau (avant ajustement BB) ───────────────

  int _baseDistance(SwimLevel level) => switch (level) {
        SwimLevel.beginner => 1500,
        SwimLevel.intermediate => 2000,
        SwimLevel.advanced => 2500,
        SwimLevel.expert => 3000,
      };

  // ── Construction des blocs ────────────────────────────────────────────────

  List<TrainingBlock> _buildBlocks(
      _SessionType type, int totalDistance, SwimLevel level) {
    return switch (type) {
      _SessionType.endurance => _enduranceBlocks(totalDistance, level),
      _SessionType.threshold => _thresholdBlocks(totalDistance, level),
      _SessionType.recovery => _recoveryBlocks(totalDistance),
    };
  }

  List<TrainingBlock> _enduranceBlocks(int total, SwimLevel level) {
    final warmup = 400;
    final cooldown = 200;
    final drillsDistance = 200;
    final mainDistance = total - warmup - cooldown - drillsDistance;
    final mainReps = level == SwimLevel.beginner ? 4 : 6;
    final mainDist = (mainDistance / mainReps / 50).round() * 50;

    return [
      TrainingBlock(
        name: 'Échauffement',
        type: BlockType.warmup,
        repetitions: 1,
        distanceMeters: warmup,
        description: 'Nage libre, allure confortable',
        intensity: Intensity.easy,
      ),
      TrainingBlock(
        name: 'Éducatifs',
        type: BlockType.drill,
        repetitions: 4,
        distanceMeters: 50,
        description: 'Catch-up / bras tendu — focus sur le timing',
        intensity: Intensity.easy,
        restDuration: const Duration(seconds: 15),
      ),
      TrainingBlock(
        name: 'Endurance fondamentale',
        type: BlockType.main,
        repetitions: mainReps,
        distanceMeters: mainDist,
        description: 'Allure endurance — respiration contrôlée',
        intensity: Intensity.moderate,
        restDuration: const Duration(seconds: 20),
        strokeType: StrokeType.freestyle,
      ),
      TrainingBlock(
        name: 'Retour au calme',
        type: BlockType.cooldown,
        repetitions: 1,
        distanceMeters: cooldown,
        description: 'Dos crawlé, très lent',
        intensity: Intensity.easy,
        strokeType: StrokeType.backstroke,
      ),
    ];
  }

  List<TrainingBlock> _thresholdBlocks(int total, SwimLevel level) {
    final warmup = 400;
    final cooldown = 200;
    final mainDistance = total - warmup - cooldown;
    final repDist = level == SwimLevel.beginner ? 100 : 200;
    final reps = (mainDistance / repDist).round();

    return [
      TrainingBlock(
        name: 'Échauffement',
        type: BlockType.warmup,
        repetitions: 1,
        distanceMeters: warmup,
        description: '200m libre + 2×100m progressifs',
        intensity: Intensity.easy,
      ),
      TrainingBlock(
        name: 'Seuil',
        type: BlockType.threshold,
        repetitions: reps,
        distanceMeters: repDist,
        description: 'Allure seuil — effort soutenu mais contrôlé (~85% FCmax)',
        intensity: Intensity.threshold,
        restDuration: const Duration(seconds: 30),
        strokeType: StrokeType.freestyle,
      ),
      TrainingBlock(
        name: 'Retour au calme',
        type: BlockType.cooldown,
        repetitions: 1,
        distanceMeters: cooldown,
        description: 'Nage lente, 4 styles',
        intensity: Intensity.easy,
      ),
    ];
  }

  List<TrainingBlock> _recoveryBlocks(int total) {
    final dist = (total * 0.7).round();
    return [
      TrainingBlock(
        name: 'Récupération active',
        type: BlockType.recovery,
        repetitions: 1,
        distanceMeters: dist,
        description: 'Nage très confortable, pas de montre — technique uniquement',
        intensity: Intensity.easy,
      ),
    ];
  }
}

enum _SessionType { endurance, threshold, recovery }
