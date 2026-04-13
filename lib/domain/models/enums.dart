/// Type d'activité natation
enum ActivityType {
  pool,      // Piscine — POOL_SWIMMING Garmin
  openWater, // Eau libre — OPEN_WATER_SWIMMING Garmin
}

/// Source de la montre connectée
enum WatchSource {
  garmin,
  coros,
  apple,
  polar,
  manual, // Saisie manuelle
}

/// Type de nage
enum StrokeType {
  freestyle,   // Crawl
  backstroke,  // Dos
  breaststroke,// Brasse
  butterfly,   // Papillon
  mixed,       // Mixte
  unknown,
}

/// Niveau du nageur (calculé depuis l'historique)
enum SwimLevel {
  beginner,     // Débutant : SWOLF > 60, allure > 3min/100m
  intermediate, // Intermédiaire : SWOLF 45–60, allure 2–3min/100m
  advanced,     // Avancé : SWOLF 35–45, allure 1:30–2min/100m
  expert,       // Expert : SWOLF < 35, allure < 1:30/100m
}

/// Objectif principal du nageur
enum SwimGoal {
  generalFitness,    // Santé / forme générale
  poolProgression,   // Progression en piscine
  openWaterPrep,     // Préparation eau libre
  triathlonPrep,     // Préparation triathlon
  competition,       // Compétition
}

/// Type de bloc dans une séance d'entraînement
enum BlockType {
  warmup,    // Échauffement
  drill,     // Éducatifs / technique
  main,      // Bloc principal
  threshold, // Seuil
  recovery,  // Récupération
  cooldown,  // Retour au calme
}

/// Statut d'une séance planifiée
enum SessionStatus {
  planned,   // Planifiée, pas encore faite
  completed, // Réalisée
  skipped,   // Passée / sautée
  rest,      // Jour de repos
}

/// Niveau d'intensité
enum Intensity {
  easy,      // Endurance fondamentale — ~65% FCmax
  moderate,  // Aérobie — ~75% FCmax
  threshold, // Seuil — ~85% FCmax
  hard,      // Haute intensité — ~90% FCmax
}
