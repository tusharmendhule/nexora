import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/trust_widgets.dart';
import 'chats_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  /// Opens a member picker backed by `/users/suggestions` and starts a
  /// real conversation via `POST /chat`.
  Future<void> _startNewChat(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    List<User> suggestions = const [];
    try {
      final json = await api.get('/users/suggestions');
      suggestions = ((json as Map<String, dynamic>?)?['data'] as List? ?? const [])
          .map((u) => User.fromApi(u as Map<String, dynamic>))
          .toList();
    } catch (_) {/* sheet shows an empty state */}

    if (!context.mounted) return;
    final picked = await showModalBottomSheet<User>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _NewChatSheet(
        suggestions: suggestions,
        onPicked: (user) => Navigator.of(sheetContext).pop(user),
      ),
    );
    if (picked == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    final conversationId =
        await ref.read(chatsProvider.notifier).startConversation(picked.id);
    if (conversationId == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not start the conversation. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    context.push(Routes.chatDetailPath(conversationId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: () => _startNewChat(context, ref),
            icon: const Icon(Icons.edit_square),
          ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: state.chats.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
                itemBuilder: (context, index) {
                  final chat = state.chats[index];
                  final last = chat.lastMessage;
                  final isTyping = chat.participant.isOnline && last == null;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    leading: NexoraAvatar(
                      imageUrl: chat.participant.avatarUrl,
                      fallbackText: chat.participant.username,
                      size: 52,
                      online: chat.participant.isOnline,
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            chat.participant.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TrustBadge(label: chat.participant.effectiveTrustLabel, compact: true),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        isTyping ? 'typing…' : (last?.text ?? 'Say hi 👋'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: chat.unreadCount > 0
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                          fontWeight: chat.unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          last == null ? '' : Formatters.timeAgo(last.createdAt),
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                        if (chat.unreadCount > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onTap: () => context.push(Routes.chatDetailPath(chat.id)),
                  );
                },
              ),
      ),
    );
  }
}

/// Member picker for starting a new DM, backed by `/users/suggestions`.
class _NewChatSheet extends StatelessWidget {
  const _NewChatSheet({required this.suggestions, required this.onPicked});

  final List<User> suggestions;
  final ValueChanged<User> onPicked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text(
                    'New message',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: suggestions.isEmpty
                  ? Center(
                      child: Text(
                        'No suggestions right now.',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final user = suggestions[index];
                        return ListTile(
                          leading: NexoraAvatar(
                            imageUrl: user.avatarUrl,
                            fallbackText: user.username,
                            size: 48,
                            online: user.isOnline,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TrustBadge(label: user.effectiveTrustLabel, compact: true),
                            ],
                          ),
                          subtitle: Text(
                            '@${user.username} • ${user.bio.isNotEmpty ? user.bio : "Member"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => onPicked(user),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
