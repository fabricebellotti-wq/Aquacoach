import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/auth_text_field.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  BiometricType? _biometricType;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final auth = ref.read(authProvider);
    if (!auth.biometricEnabled) return;
    final type = await ref.read(authProvider.notifier).getAvailableBiometric();
    if (mounted) setState(() => _biometricType = type);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    final auth = ref.read(authProvider);
    if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
    // La navigation est gérée par le router qui écoute authProvider
  }

  Future<void> _signInBiometric() async {
    final ok = await ref.read(authProvider.notifier).signInWithBiometric();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentification biométrique échouée')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Connexion',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Bon retour ! Connecte-toi pour reprendre ta progression.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 36),

                  // Bouton biométrie si disponible
                  if (_biometricType != null) ...[
                    _BiometricSignIn(
                      type: _biometricType!,
                      onTap: _signInBiometric,
                    ),
                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 20),
                  ],

                  // Email
                  AuthTextField(
                    label: 'Adresse email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 14),

                  // Mot de passe
                  AuthTextField(
                    label: 'Mot de passe',
                    controller: _passwordCtrl,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: _submit,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
                  ),

                  // Mot de passe oublié
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: écran reset mot de passe
                      },
                      child: const Text(
                        'Mot de passe oublié ?',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bouton connexion
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Se connecter',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricSignIn extends StatelessWidget {
  const _BiometricSignIn({required this.type, required this.onTap});

  final BiometricType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFace = type == BiometricType.face;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFace ? Icons.face_unlock_outlined : Icons.fingerprint,
              color: AppColors.primary,
              size: 26,
            ),
            const SizedBox(width: 10),
            Text(
              isFace ? 'Se connecter avec Face ID' : 'Se connecter avec l\'empreinte',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFDDE7F3))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou avec ton email',
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFDDE7F3))),
      ],
    );
  }
}
