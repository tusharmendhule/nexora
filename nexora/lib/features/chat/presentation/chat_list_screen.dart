import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/trust_widgets.dart';
import 'chats_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New group chat coming with the backend 💬')),
              );
            },
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
