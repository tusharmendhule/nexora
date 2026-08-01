import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../data/moderation_models.dart';
import 'moderator_providers.dart';

class ModeratorDashboardScreen extends ConsumerWidget {
  const ModeratorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moderatorProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderator'),
        actions: [
          if (state.queue.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(moderatorProvider.notifier).resolveAll(),
              child: const Text('Clear queue'),
            ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ---- KPIs --------------------------------------------
                  Row(
                    children: [
                      _KpiCard(
                        label: 'Pending',
                        value: '${state.stats.pending}',
                        icon: Icons.hourglass_top_rounded,
                        color: AppColors.trustOrange,
                      ),
                      const SizedBox(width: 10),
                      _KpiCard(
                        label: 'Resolved today',
                        value: '${state.stats.resolvedToday}',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.trustGreen,
                      ),
                      const SizedBox(width: 10),
                      _KpiCard(
                        label: 'Avg response',
                        value: '${state.stats.avgResponseHours}h',
                        icon: Icons.timer_outlined,
                        color: AppColors.trustBlue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GlassCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: BorderRadius.circular(18),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.accentCyan, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI triage is active — ${state.stats.trustActions} trust actions applied this week. Human review is always final.',
                            style: const TextStyle(fontSize: 12.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SectionHeader(
                    title: 'Moderation queue',
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  ),
                  const SizedBox(height: 8),
                  if (state.queue.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          const Icon(Icons.verified_rounded, size: 56, color: AppColors.trustGreen),
                          const SizedBox(height: 12),
                          Text(
                            'Queue clear! 🎉',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No reports awaiting review.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final item in state.queue) _QueueCard(item: item),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NexoraCard(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.item});

  final ModerationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final reason = item.reasonModel;
    final reportedUser = item.reportedUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: reason.color.withValues(alpha: item.severity >= 3 ? 0.7 : 0.35),
          width: item.severity >= 3 ? 1.4 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: reason.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(reason.icon, size: 18, color: reason.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: reason.color,
                        ),
                      ),
                      Text(
                        'Reported ${Formatters.timeAgo(item.reportedAt)} ago',
                        style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (item.severity >= 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.trustRed.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      'URGENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.trustRed,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl: item.preview,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 84,
                  height: 84,
                  color: scheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          NexoraAvatar(
                            imageUrl: reportedUser?.avatarUrl,
                            fallbackText: reportedUser?.username,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '@${reportedUser?.username ?? "unknown"}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          ),
                          if (reportedUser != null) ...[
                            const SizedBox(width: 6),
                            TrustBadge(label: reportedUser.effectiveTrustLabel, compact: true),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(moderatorProvider.notifier).resolve(item.id),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Dismiss'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurfaceVariant,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      ref.read(moderatorProvider.notifier).takeAction(item.id, 'remove');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Action logged — @${reportedUser?.username ?? "user"} was notified.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.gavel_rounded, size: 16),
                    label: const Text('Take action'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.trustRed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(40),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
