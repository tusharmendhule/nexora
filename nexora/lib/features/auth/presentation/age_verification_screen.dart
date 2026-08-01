import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/common.dart';
import 'auth_provider.dart';

class AgeVerificationScreen extends ConsumerStatefulWidget {
  const AgeVerificationScreen({super.key});

  @override
  ConsumerState<AgeVerificationScreen> createState() => _AgeVerificationScreenState();
}

class _AgeVerificationScreenState extends ConsumerState<AgeVerificationScreen> {
  DateTime? _dob;
  final bool _confirmed = false;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Select your date of birth',
    );
    if (picked != null) setState(() => _dob = picked);
  }

  int get _age {
    if (_dob == null) return 0;
    final now = DateTime.now();
    var age = now.year - _dob!.year;
    if (now.month < _dob!.month || (now.month == _dob!.month && now.day < _dob!.day)) {
      age--;
    }
    return age;
  }

  bool get _isEligible => _age >= 16;

  void _finish() {
    ref.read(authProvider.notifier).completeAgeVerification();
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Age verification')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.faded(AppColors.brandGradient, 0.16),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  size: 44,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verify your age',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Nexora is an all-ages community, but accounts are restricted to members aged 16 and over. This keeps conversations safe and trustworthy.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              NexoraCard(
                padding: const EdgeInsets.all(18),
                onTap: _pickDate,
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.brand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.cake_rounded, color: AppColors.brand),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dob == null ? 'Date of birth' : 'Date of birth',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dob == null
                                ? 'Tap to select'
                                : Formatters.readableDate(_dob!),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _dob == null ? scheme.onSurface : AppColors.brand,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  ],
                ),
              ),
              if (_dob != null) ...[
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _isEligible
                      ? Container(
                          key: const ValueKey('ok'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.trustGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.trustGreen.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.trustGreen),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You are $_age years old — you can join Nexora. 🎉',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.trustGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Container(
                          key: const ValueKey('no'),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.trustRed.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.trustRed.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: AppColors.trustRed),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Nexora requires members to be at least 16 years old.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.trustRed,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'I confirm and continue',
                loading: _dob != null && _confirmed && false,
                onPressed: _isEligible && _dob != null ? _finish : null,
              ),
              const SizedBox(height: 12),
              Text(
                'Your date of birth is never shown publicly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
