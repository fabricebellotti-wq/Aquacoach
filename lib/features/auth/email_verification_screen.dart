import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import 'biometric_setup_screen.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen> {
  // 6 controllers, un par chiffre
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  bool _hasError = false;

  // Compteur pour renvoyer le code
  int _resendCountdown = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _resendCountdown--);
    });
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    final code = _otpCode;
    if (code.length < 6) return;

    setState(() {
      _loading = true;
      _hasError = false;
    });

    final ok = await ref.read(authProvider.notifier).verifyOtp(code);

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      // Succès → écran setup biométrie
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BiometricSetupScreen()),
      );
    } else {
      setState(() => _hasError = true);
      HapticFeedback.heavyImpact();
      // Vide les champs et remet le focus sur le premier
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(authProvider.notifier).resendOtp();
    _startResendTimer();
    messenger.showSnackBar(
      const SnackBar(content: Text('Nouveau code envoyé !')),
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Icône email
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 20),

              Text('Vérifie ta boîte mail',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                  children: [
                    const TextSpan(text: 'Nous avons envoyé un code à '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Champs OTP
              _OtpInput(
                controllers: _controllers,
                focusNodes: _focusNodes,
                hasError: _hasError,
                onCompleted: _verify,
              ),

              if (_hasError) ...[
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 14, color: AppColors.error),
                    SizedBox(width: 6),
                    Text(
                      'Code incorrect. Réessaie.',
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 36),

              // Bouton vérifier
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_loading || _otpCode.length < 6) ? null : _verify,
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
                      : const Text('Vérifier le code',
                          style: TextStyle(fontSize: 16)),
                ),
              ),

              const SizedBox(height: 24),

              // Renvoyer le code
              Center(
                child: _resendCountdown > 0
                    ? Text(
                        'Renvoyer le code dans $_resendCountdown s',
                        style: const TextStyle(
                            color: AppColors.textHint, fontSize: 14),
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: const Text(
                          'Renvoyer le code',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
              ),

              const Spacer(),

              // Note sécurité
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.textHint),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le code expire dans 10 minutes. Ne le partage jamais.',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.textHint),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widget OTP ────────────────────────────────────────────────────────────────

class _OtpInput extends StatelessWidget {
  const _OtpInput({
    required this.controllers,
    required this.focusNodes,
    required this.hasError,
    required this.onCompleted,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool hasError;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) => _OtpCell(
        controller: controllers[i],
        focusNode: focusNodes[i],
        hasError: hasError,
        onChanged: (val) {
          if (val.isNotEmpty) {
            if (i < 5) {
              focusNodes[i + 1].requestFocus();
            } else {
              focusNodes[i].unfocus();
              onCompleted();
            }
          }
        },
        onBackspace: () {
          if (controllers[i].text.isEmpty && i > 0) {
            controllers[i - 1].clear();
            focusNodes[i - 1].requestFocus();
          }
        },
      )),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 60,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: hasError ? AppColors.error : AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: hasError
                ? AppColors.error.withAlpha(15)
                : AppColors.cardLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error.withAlpha(80)
                    : const Color(0xFFDDE7F3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
