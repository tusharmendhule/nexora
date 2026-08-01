import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../data/models.dart';
import 'notifications_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                onTap: (i) => ref.read(notificationsProvider.notifier).setTab(i),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Mentions'),
                  Tab(text: 'Trust'),
                ],
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _NotificationList(
                            items: state.items,
                            onTap: (n) =>
                                ref.read(notificationsProvider.notifier).markRead(n.id),
                          ),
                          _NotificationList(
                            items: state.items
                                .where((n) => n.type == NotificationType.mention)
                                .toList(),
                            onTap: (n) =>
                                ref.read(notificationsProvider.notifier).markRead(n.id),
                          ),
                          _NotificationList(
                            items: state.items
                                .where((n) => n.isTrustEvent)
                                .toList(),
                            onTap: (n) =>
                                ref.read(notificationsProvider.notifier).markRead(n.id),
                            trustMode: true,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.onTap,
    this.trustMode = false,
  });

  final List<AppNotification> items;
  final ValueChanged<AppNotification> onTap;
  final bool trustMode;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: trustMode ? Icons.shield_outlined : Icons.notifications_none_rounded,
        title: trustMode ? 'No trust events' : 'You\'re all caught up',
        subtitle: trustMode
            ? 'Trust label changes and safety milestones will appear here.'
            : 'Likes, comments and follows will land here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
      itemBuilder: (context, index) {
        final n = items[index];
        return ListTile(
          onTap: () => onTap(n),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              NexoraAvatar(
                imageUrl: n.user.avatarUrl,
                fallbackText: n.user.username,
                size: 44,
              ),
              Positioned(
                right: -4,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _iconColor(n.type),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(_icon(n.type), size: 12, color: Colors.white),
                ),
              ),
            ],
          ),
          title: RichText(
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontSize: 13.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              children: [
                TextSpan(
                  text: n.user.username,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ' ${n.text}'),
              ],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              children: [
                Text(
                  Formatters.timeAgo(n.createdAt),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (n.type == NotificationType.trust) ...[
                  const SizedBox(width: 8),
                  TrustBadge(label: n.user.effectiveTrustLabel, compact: true),
                ],
              ],
            ),
          ),
          trailing: n.postPreview != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: n.postPreview!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                )
              : n.isRead
                  ? null
                  : Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.brand,
                      ),
                    ),
          onLongPress: () => context.push(Routes.profilePath(n.user.id)),
        );
      },
    );
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Icons.favorite_rounded;
      case NotificationType.comment:
        return Icons.chat_bubble_rounded;
      case NotificationType.follow:
        return Icons.person_add_rounded;
      case NotificationType.mention:
        return Icons.alternate_email_rounded;
      case NotificationType.trust:
        return Icons.shield_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }

  Color _iconColor(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return Colors.redAccent;
      case NotificationType.comment:
        return AppColors.trustBlue;
      case NotificationType.follow:
        return AppColors.trustGreen;
      case NotificationType.mention:
        return AppColors.accentCyan;
      case NotificationType.trust:
        return AppColors.trustPurple;
      case NotificationType.system:
        return AppColors.trustOrange;
    }
  }
}
