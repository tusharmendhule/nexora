import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/common.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await ref
        .read(authProvider.notifier)
        .signIn(_email.text.trim(), _password.text);
    if (ok && mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF14101F), Color(0xFF1B1233), Color(0xFF0E1A2B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradientDeep,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.diversity_3_rounded, color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sign in to your Nexora community',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 28),
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: BorderRadius.circular(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email address',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white54),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.white54,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.trustRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Sign in',
                        loading: auth.isLoading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      final ok = await ref
                                          .read(authProvider.notifier)
                                          .signInAsGuest();
                                      if (ok && context.mounted) {
                                        context.go(Routes.home);
                                      }
                                    },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                                minimumSize: const Size.fromHeight(48),
                              ),
                              icon: const Icon(Icons.person_outline_rounded, size: 18),
                              label: const Text('Continue as guest'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset will be available with the backend 📧'),
                            ),
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New to Nexora?',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    TextButton(
                      onPressed: () => context.push(Routes.register),
                      child: const Text(
                        'Create account',
                        style: TextStyle(
                          color: AppColors.accentCyan,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'By continuing you agree to the Community Guidelines and trust that every member is human, verified, and kind.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
