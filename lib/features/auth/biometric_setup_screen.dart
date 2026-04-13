import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';

/// Proposé juste après la vérification OTP — configure Face ID ou empreinte
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() =>
      _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  BiometricType? _biometricType;
  bool _loading = true;
  bool _activating = false;

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    final type =
        await ref.read(authProvider.notifier).getAvailableBiometric();
    if (mounted) {
      setState(() {
        _biometricType = type;
        _loading = false;
      });
    }
  }

  Future<void> _activate() async {
    setState(() => _activating = true);
    final ok = await ref.read(authProvider.notifier).enableBiometric();
    if (!mounted) return;
    setState(() => _activating = false);

    if (ok) {
      _navigateToApp();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activation annulée ou non disponible.'),
        ),
      );
    }
  }

  void _navigateToApp() {
    // Le router écoute authProvider et redirige automatiquement vers /today
    // On pop jusqu'à la racine pour laisser le router prendre la main
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isFace = _biometricType == BiometricType.face;
    final hasFingerprint = _biometricType == BiometricType.fingerprint ||
        _biometricType == BiometricType.strong;
    final hasBiometric = isFace || hasFingerprint;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Illustration
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  hasBiometric
                      ? (isFace
                          ? Icons.face_unlock_outlined
                          : Icons.fingerprint)
                      : Icons.lock_outline,
                  size: 52,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),

              // Titre
              Text(
                hasBiometric
                    ? (isFace
                        ? 'Activer Face ID'
                        : 'Activer l\'empreinte digitale')
                    : 'Connexion rapide',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                hasBiometric
                    ? 'La prochaine fois, connecte-toi en une fraction de seconde — sans taper de mot de passe.'
                    : 'Aucun capteur biométrique détecté sur ce device.',
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Avantages
              if (hasBiometric) ...[
                _BenefitRow(
                  icon: Icons.bolt_outlined,
                  text: 'Connexion instantanée au bord du bassin',
                ),
                const SizedBox(height: 12),
                _BenefitRow(
                  icon: Icons.shield_outlined,
                  text: 'Tes données ne quittent jamais ton téléphone',
                ),
                const SizedBox(height: 12),
                _BenefitRow(
                  icon: Icons.block_outlined,
                  text: 'Désactivable à tout moment dans les paramètres',
                ),
                const SizedBox(height: 40),
              ],

              const Spacer(),

              // Bouton activer
              if (hasBiometric)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _activating ? null : _activate,
                    icon: _activating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Icon(isFace
                            ? Icons.face_unlock_outlined
                            : Icons.fingerprint),
                    label: Text(
                      isFace ? 'Activer Face ID' : 'Activer l\'empreinte',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // Passer
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _navigateToApp,
                  child: Text(
                    hasBiometric ? 'Pas maintenant' : 'Continuer',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
