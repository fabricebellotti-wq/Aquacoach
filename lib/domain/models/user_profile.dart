import 'enums.dart';

/// Profil nageur stocké dans Firestore — users/{userId}
class UserProfile {
  const UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.goal,
    required this.weeklyFrequency,
    required this.connectedWatch,
    required this.createdAt,
    this.level,
    this.poolLength = 25,
    this.lastSyncAt,
  });

  final String id;
  final String displayName;
  final String email;
  final SwimGoal goal;

  /// Nombre de séances souhaitées par semaine (3–5)
  final int weeklyFrequency;

  final WatchSource connectedWatch;
  final DateTime createdAt;

  /// Niveau calculé automatiquement depuis l'historique — null avant calibration
  final SwimLevel? level;

  /// Longueur de bassin préférée (25 ou 50m)
  final int poolLength;

  final DateTime? lastSyncAt;

  UserProfile copyWith({
    SwimLevel? level,
    SwimGoal? goal,
    int? weeklyFrequency,
    WatchSource? connectedWatch,
    int? poolLength,
    DateTime? lastSyncAt,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName,
      email: email,
      goal: goal ?? this.goal,
      weeklyFrequency: weeklyFrequency ?? this.weeklyFrequency,
      connectedWatch: connectedWatch ?? this.connectedWatch,
      createdAt: createdAt,
      level: level ?? this.level,
      poolLength: poolLength ?? this.poolLength,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'goal': goal.name,
        'weeklyFrequency': weeklyFrequency,
        'connectedWatch': connectedWatch.name,
        'createdAt': createdAt.toIso8601String(),
        'level': level?.name,
        'poolLength': poolLength,
        'lastSyncAt': lastSyncAt?.toIso8601String(),
      };

  factory UserProfile.fromFirestore(String id, Map<String, dynamic> data) {
    return UserProfile(
      id: id,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      goal: SwimGoal.values.byName(data['goal'] as String),
      weeklyFrequency: data['weeklyFrequency'] as int,
      connectedWatch: WatchSource.values.byName(data['connectedWatch'] as String),
      createdAt: DateTime.parse(data['createdAt'] as String),
      level: data['level'] != null
          ? SwimLevel.values.byName(data['level'] as String)
          : null,
      poolLength: data['poolLength'] as int? ?? 25,
      lastSyncAt: data['lastSyncAt'] != null
          ? DateTime.parse(data['lastSyncAt'] as String)
          : null,
    );
  }
}
