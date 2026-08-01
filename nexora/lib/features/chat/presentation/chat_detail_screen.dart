import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/avatar.dart';
import '../../auth/presentation/auth_provider.dart';
import 'chats_providers.dart';
import 'widgets/chat_bubble.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _composer = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        final target = _scroll.position.maxScrollExtent;
        if (animate) {
          _scroll.animateTo(
            target,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scroll.jumpTo(target);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Pull the full thread from the API when the chat opens.
    Future<void>.microtask(() {
      if (mounted) {
        ref.read(chatsProvider.notifier).loadMessages(widget.chatId);
        _scrollToBottom(animate: false);
      }
    });
  }

  Future<void> _send() async {
    final text = _composer.text;
    if (text.trim().isEmpty) return;
    await ref.read(chatsProvider.notifier).sendMessage(widget.chatId, text);
    _composer.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatsProvider);
    final chat = state.chats.where((c) => c.id == widget.chatId).firstOrNull;
    final scheme = Theme.of(context).colorScheme;

    if (chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Conversation not found.')),
      );
    }

    final peer = chat.participant;
    final trustColor = peer.effectiveTrustLabel.color;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            NexoraAvatar(
              imageUrl: peer.avatarUrl,
              fallbackText: peer.username,
              size: 36,
              online: peer.isOnline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  Text(
                    peer.isOnline ? 'Active now' : 'Trust ${peer.effectiveTrustLabel.label}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: peer.isOnline ? AppColors.trustGreen : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(Routes.profilePath(peer.id)),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Trust banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: trustColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: trustColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, size: 16, color: trustColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '@${peer.username} carries the ${peer.effectiveTrustLabel.label} Trust Label',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: trustColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: chat.messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == chat.messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text('typing…', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }
                  final message = chat.messages[index];
                  final meId = ref.read(authProvider).user?.id;
                  return ChatBubble(
                    message: message,
                    isMine: meId != null && message.senderId == meId,
                    trustColor: trustColor,
                  );
                },
              ),
            ),
            // Composer
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      onTap: _scrollToBottom,
                      decoration: const InputDecoration(
                        hintText: 'Message…',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: trustColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
