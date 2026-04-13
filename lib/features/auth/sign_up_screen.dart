import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'email_verification_screen.dart';
import 'widgets/auth_text_field.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    await ref.read(authProvider.notifier).signUp(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.pendingVerification) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => EmailVerificationScreen(email: _emailCtrl.text.trim()),
      ));
    } else if (auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.error,
        ),
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

                  // Titre
                  Text('Créer un compte',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  const Text(
                    'Rejoins des milliers de nageurs qui progressent avec leurs données.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Prénom
                  AuthTextField(
                    label: 'Prénom',
                    controller: _nameCtrl,
                    prefixIcon: Icons.person_outline,
                    autofillHints: const [AutofillHints.givenName],
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 14),

                  // Email
                  AuthTextField(
                    label: 'Adresse email',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    autofillHints: const [AutofillHints.email],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Champ obligatoire';
                      if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v.trim())) {
                        return 'Email invalide';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mot de passe
                  AuthTextField(
                    label: 'Mot de passe',
                    controller: _passwordCtrl,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Champ obligatoire';
                      if (v.length < 8) return '8 caractères minimum';
                      return null;
                    },
                  ),
                  const SizedBox(height: 6),
                  const _PasswordStrengthHint(),
                  const SizedBox(height: 14),

                  // Confirmation mot de passe
                  AuthTextField(
                    label: 'Confirmer le mot de passe',
                    controller: _confirmCtrl,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: _submit,
                    validator: (v) {
                      if (v != _passwordCtrl.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bouton créer
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
                          : const Text('Créer mon compte',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Sécurité note
                  const _SecurityNote(),
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

class _PasswordStrengthHint extends StatelessWidget {
  const _PasswordStrengthHint();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        '8 caractères minimum, avec majuscule et chiffre recommandés',
        style: TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  const _SecurityNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: const Row(
        children: [
          Icon(Icons.security_outlined, size: 16, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Un code à 6 chiffres sera envoyé à ton adresse email pour vérifier ton identité.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
