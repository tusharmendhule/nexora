import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../../auth/presentation/auth_provider.dart';
import 'trust_center_providers.dart';

class TrustCenterScreen extends ConsumerWidget {
  const TrustCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final user = ref.watch(authProvider.select((s) => s.user));
    final overview = ref.watch(trustCenterProvider).overview;
    final score = user?.trustScore ?? 50;
    final label = user?.effectiveTrustLabel ?? TrustLabel.verified;

    return Scaffold(
      appBar: AppBar(title: const Text('Trust Center')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- Score gauge --------------------------------------------
            GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(26),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TrustScoreGauge(score: score, size: 220),
                  const SizedBox(height: 12),
                  TrustBadge(label: label),
                  const SizedBox(height: 8),
                  Text(
                    label.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Legend(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- What this means ----------------------------------------
            const NexoraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How your score works',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.verified_user_outlined,
                    color: AppColors.trustGreen,
                    text: 'Identity is verified through documents and device signals.',
                  ),
                  _InfoRow(
                    icon: Icons.auto_awesome_outlined,
                    color: AppColors.trustBlue,
                    text: 'Original content boosts your quality score; re-posting spam hurts it.',
                  ),
                  _InfoRow(
                    icon: Icons.people_outline_rounded,
                    color: AppColors.trustPurple,
                    text: 'Community feedback — likes, reports and blocks — feeds the model.',
                  ),
                  _InfoRow(
                    icon: Icons.timeline_rounded,
                    color: AppColors.trustOrange,
                    text: 'Consistent, positive activity grows your score over time.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Factors -------------------------------------------------
            const SectionHeader(title: 'Your factors'),
            const SizedBox(height: 8),
            NexoraCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (overview.factors.isEmpty)
                      Text(
                        'No trust factors yet — post content to build your score.',
                        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                      )
                    else
                      for (final factor in overview.factors)
                        TrustBar(
                          label: factor.label,
                          value: factor.value,
                          color: factor.color,
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- History -------------------------------------------------
            const SectionHeader(title: '8-week history'),
            const SizedBox(height: 8),
            NexoraCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final point in overview.history)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    '${point.score.round()}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: point.score),
                                    duration: const Duration(milliseconds: 800),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) => Container(
                                      height: (value / 100) * 88,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.brandGradientDeep,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final point in overview.history)
                        Expanded(
                          child: Text(
                            point.week,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 9.5, color: scheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Tips ----------------------------------------------------
            const SectionHeader(title: 'Grow your trust'),
            const SizedBox(height: 8),
            const NexoraCard(
              child: Column(
                children: [
                  _TipTile(
                    icon: Icons.verified_rounded,
                    title: 'Verify your identity',
                    subtitle: 'Add a government ID to unlock the Verified label.',
                    color: AppColors.trustGreen,
                  ),
                  _TipTile(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Post original content',
                    subtitle: 'Original posts score 3× higher than reshared content.',
                    color: AppColors.trustBlue,
                  ),
                  _TipTile(
                    icon: Icons.volunteer_activism_rounded,
                    title: 'Help the community',
                    subtitle: 'Answer questions and moderate fairly to earn trust points.',
                    color: AppColors.trustPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final label in TrustLabel.values) TrustBadge(label: label, compact: true),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
    );
  }
}
