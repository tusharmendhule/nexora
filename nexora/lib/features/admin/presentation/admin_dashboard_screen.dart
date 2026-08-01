import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../data/admin_models.dart';
import 'admin_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _maintenance = false;
  bool _aiTriage = true;
  bool _verifiedOnlyExplore = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(adminProvider);
    final stats = state.stats;

    if (state.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: ErrorState(
          message: state.error!,
          onRetry: () => ref.read(adminProvider.notifier).refresh(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.trustGreen.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.trustGreen),
                SizedBox(width: 5),
                Text(
                  'All systems operational',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.trustGreen),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- KPIs ---------------------------------------------------
            Row(
              children: [
                _Kpi(
                  label: 'Members',
                  value: _compact(stats.users),
                  delta: _growthPct(stats.growth),
                  icon: Icons.groups_rounded,
                  color: AppColors.brand,
                ),
                const SizedBox(width: 10),
                _Kpi(
                  label: 'Posts',
                  value: _compact(stats.posts),
                  delta: '',
                  icon: Icons.article_rounded,
                  color: AppColors.trustBlue,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _Kpi(
                  label: 'Open reports',
                  value: '${stats.openReports}',
                  delta: '',
                  icon: Icons.flag_rounded,
                  color: AppColors.trustOrange,
                ),
                const SizedBox(width: 10),
                _Kpi(
                  label: 'Trust results',
                  value: _compact(stats.trustResults),
                  delta: '',
                  icon: Icons.shield_rounded,
                  color: AppColors.trustGreen,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ---- Growth chart -------------------------------------------
            NexoraCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Member growth (K)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 130,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final point in stats.growth)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: (point.members / (stats.users > 0 ? stats.users : 1)).clamp(0.0, 1.0)),
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, value, _) => Container(
                                      height: value * 100,
                                      decoration: const BoxDecoration(
                                        gradient: AppColors.brandGradientDeep,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    point.week,
                                    style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ---- Communities ---------------------------------------------
            const SectionHeader(
              title: 'Top members by trust',
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            const SizedBox(height: 8),
            NexoraCard(
              padding: const EdgeInsets.all(16),
              child: stats.topUsers.isEmpty
                  ? Text(
                      'No members yet.',
                      style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                    )
                  : Column(
                      children: [
                        for (final member in stats.topUsers)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: member['role'] == 'admin'
                                        ? AppColors.trustRed
                                        : AppColors.trustGreen,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    member['name'] as String? ?? 'Member',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                ),
                                Text(
                                  '@${member['username'] ?? ''}',
                                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                ),
                                const SizedBox(width: 10),
                                TrustBadge(
                                  label: TrustLabel.fromScore(
                                    ((member['trustScore'] as num?) ?? 50).toDouble(),
                                  ),
                                  compact: true,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // ---- System controls ------------------------------------------
            const SectionHeader(
              title: 'System controls',
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            const SizedBox(height: 8),
            NexoraCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('AI trust triage', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Auto-triage low-risk reports'),
                    value: _aiTriage,
                    onChanged: (v) => setState(() => _aiTriage = v),
                  ),
                  SwitchListTile(
                    title: const Text('Verified-only Explore', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Prioritize verified creators'),
                    value: _verifiedOnlyExplore,
                    onChanged: (v) => setState(() => _verifiedOnlyExplore = v),
                  ),
                  SwitchListTile(
                    title: const Text('Maintenance mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.trustRed)),
                    subtitle: const Text('Read-only for all members'),
                    value: _maintenance,
                    activeTrackColor: AppColors.trustRed,
                    onChanged: (v) => setState(() => _maintenance = v),
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
  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _growthPct(List<AdminGrowthPoint> growth) {
    if (growth.length < 2) return '';
    final last = growth.last.members;
    final prev = growth[growth.length - 2].members;
    if (prev <= 0) return '';
    final pct = (((last - prev) / prev) * 100).round();
    return pct >= 0 ? '+$pct%' : '$pct%';
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: NexoraCard(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: color),
                ),
                const Spacer(),
                Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: delta.startsWith('+') ? AppColors.trustGreen : AppColors.trustRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
            Text(
              label,
              style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
