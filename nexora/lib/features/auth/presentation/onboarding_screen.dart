import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import 'auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingData {
  const _OnboardingData(this.icon, this.title, this.subtitle, this.colors);

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
}

const List<_OnboardingData> _pages = [
  _OnboardingData(
    Icons.diversity_3_rounded,
    'Welcome to Nexora',
    'A social platform where community and connection come first — built for the next generation.',
    [Color(0xFF6C5CE7), Color(0xFFF472B6)],
  ),
  _OnboardingData(
    Icons.shield_rounded,
    'Trust-first by design',
    'Every member carries a Trust Score and color-coded Trust Label. Verified voices rise, noise fades.',
    [Color(0xFF22C55E), Color(0xFF0EA5E9)],
  ),
  _OnboardingData(
    Icons.rocket_launch_rounded,
    'Share your world',
    'Posts, reels, stories, live spaces and DMs — create and connect with confidence.',
    [Color(0xFFF59E0B), Color(0xFFEF4444)],
  ),
];

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(authProvider.notifier).completeOnboarding();
    context.go(Routes.login);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text(
                    'Skip',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: page.colors,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: page.colors.first.withValues(alpha: 0.4),
                                blurRadius: 50,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Icon(page.icon, size: 84, color: Colors.white),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15.5,
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 26 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _index ? AppColors.brand : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: PrimaryButtonLarge(
                label: _index == _pages.length - 1 ? 'Get started' : 'Next',
                icon: _index == _pages.length - 1 ? Icons.arrow_forward_rounded : null,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local gradient button (mirrors shared PrimaryButton to keep onboarding self-contained).
class PrimaryButtonLarge extends StatelessWidget {
  const PrimaryButtonLarge({super.key, required this.label, this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradientDeep,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, color: Colors.white, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
