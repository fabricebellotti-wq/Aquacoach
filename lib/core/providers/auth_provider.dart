import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

// ── Modèle d'état auth ────────────────────────────────────────────────────────

enum AuthStatus {
  unknown,         // Initialisation
  unauthenticated, // Pas connecté
  pendingVerification, // OTP envoyé, en attente de vérification
  authenticated,   // Connecté et vérifié
}

class AuthState {
  const AuthState({
    required this.status,
    this.userId,
    this.email,
    this.displayName,
    this.isEmailVerified = false,
    this.biometricEnabled = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final String? displayName;
  final bool isEmailVerified;
  final bool biometricEnabled;
  final String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? userId,
    String? email,
    String? displayName,
    bool? isEmailVerified,
    bool? biometricEnabled,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      errorMessage: errorMessage,
    );
  }
}

// ── AuthNotifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(status: AuthStatus.unknown)) {
    _init();
  }

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  // Code OTP en mémoire (ne jamais persister en clair)
  String? _pendingOtp;
  String? _pendingEmail;
  String? _pendingName;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final userId = await _storage.read(key: 'auth_user_id');
    final biometricEnabled =
        await _storage.read(key: 'biometric_enabled') == 'true';

    if (userId != null) {
      final email = await _storage.read(key: 'auth_email') ?? '';
      final name = await _storage.read(key: 'auth_name') ?? '';
      state = AuthState(
        status: AuthStatus.authenticated,
        userId: userId,
        email: email,
        displayName: name,
        isEmailVerified: true,
        biometricEnabled: biometricEnabled,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Inscription ─────────────────────────────────────────────────────────────

  /// Étape 1 : création du compte — envoie un OTP par email
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(status: AuthStatus.unknown, errorMessage: null);

    try {
      // Génère un code OTP à 6 chiffres
      final otp = _generateOtp();
      _pendingOtp = otp;
      _pendingEmail = email;
      _pendingName = displayName;

      // TODO (Firebase) : créer le compte avec firebase_auth,
      //   puis envoyer le code via une Cloud Function :
      //   await FirebaseFunctions.instance
      //     .httpsCallable('sendVerificationCode')
      //     .call({'email': email, 'code': otp});
      //
      // Pour le MVP mock : on logue le code en debug uniquement
      if (kDebugMode) debugPrint('🔐 OTP mock pour $email : $otp');

      // Simulation délai réseau
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(
        status: AuthStatus.pendingVerification,
        email: email,
        displayName: displayName,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _friendlyError(e),
      );
    }
  }

  /// Étape 2 : vérification du code OTP
  Future<bool> verifyOtp(String code) async {
    if (_pendingOtp == null) return false;

    await Future.delayed(const Duration(milliseconds: 600));

    if (code == _pendingOtp) {
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';

      // Persiste la session
      await _storage.write(key: 'auth_user_id', value: userId);
      await _storage.write(key: 'auth_email', value: _pendingEmail ?? '');
      await _storage.write(key: 'auth_name', value: _pendingName ?? '');

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userId: userId,
        email: _pendingEmail,
        displayName: _pendingName,
        isEmailVerified: true,
        errorMessage: null,
      );

      _pendingOtp = null;
      return true;
    } else {
      state = state.copyWith(errorMessage: 'Code incorrect. Réessaie.');
      return false;
    }
  }

  /// Renvoie un nouveau code OTP
  Future<void> resendOtp() async {
    if (_pendingEmail == null) return;
    final newOtp = _generateOtp();
    _pendingOtp = newOtp;

    await Future.delayed(const Duration(seconds: 1));

    if (kDebugMode) debugPrint('🔐 Nouveau OTP mock pour $_pendingEmail : $newOtp');
    state = state.copyWith(errorMessage: null);
  }

  // ── Connexion ───────────────────────────────────────────────────────────────

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.unknown, errorMessage: null);

    try {
      // TODO (Firebase) :
      //   await FirebaseAuth.instance.signInWithEmailAndPassword(
      //     email: email, password: password);

      await Future.delayed(const Duration(seconds: 1));

      // Mock : accepte n'importe quel email/mdp pour l'instant
      final userId = 'user_${email.hashCode}';
      final biometricEnabled =
          await _storage.read(key: 'biometric_enabled') == 'true';

      await _storage.write(key: 'auth_user_id', value: userId);
      await _storage.write(key: 'auth_email', value: email);

      state = state.copyWith(
        status: AuthStatus.authenticated,
        userId: userId,
        email: email,
        displayName: email.split('@').first,
        isEmailVerified: true,
        biometricEnabled: biometricEnabled,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _friendlyError(e),
      );
    }
  }

  // ── Biométrie ───────────────────────────────────────────────────────────────

  /// Vérifie si le device supporte la biométrie
  Future<BiometricType?> getAvailableBiometric() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return null;
      final types = await _localAuth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BiometricType.face;
      if (types.contains(BiometricType.fingerprint)) {
        return BiometricType.fingerprint;
      }
      if (types.contains(BiometricType.strong)) return BiometricType.strong;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Active la biométrie pour les prochaines connexions
  Future<bool> enableBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Confirme ton identité pour activer la connexion biométrique',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (authenticated) {
        await _storage.write(key: 'biometric_enabled', value: 'true');
        state = state.copyWith(biometricEnabled: true);
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  /// Connexion via biométrie
  Future<bool> signInWithBiometric() async {
    try {
      final userId = await _storage.read(key: 'auth_user_id');
      if (userId == null) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Connecte-toi à AquaCoach',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (authenticated) {
        final email = await _storage.read(key: 'auth_email') ?? '';
        final name = await _storage.read(key: 'auth_name') ?? '';
        state = AuthState(
          status: AuthStatus.authenticated,
          userId: userId,
          email: email,
          displayName: name,
          isEmailVerified: true,
          biometricEnabled: true,
        );
      }
      return authenticated;
    } catch (_) {
      return false;
    }
  }

  // ── Déconnexion ─────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    // TODO (Firebase) : await FirebaseAuth.instance.signOut();
    await _storage.delete(key: 'auth_user_id');
    await _storage.delete(key: 'auth_email');
    await _storage.delete(key: 'auth_name');
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('email')) return 'Adresse email invalide.';
    if (msg.contains('password')) return 'Mot de passe trop court (min. 6 caractères).';
    if (msg.contains('network')) return 'Erreur réseau. Vérifie ta connexion.';
    if (msg.contains('already')) return 'Un compte existe déjà avec cet email.';
    return 'Une erreur est survenue. Réessaie.';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
