import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/chat/presentation/chats_providers.dart';
import '../../features/feed/data/models.dart';
import '../../features/feed/presentation/feed_providers.dart';
import 'avatar.dart';
import 'trust_widgets.dart';

/// Opens a glassmorphic bottom sheet with the given [builder] content.
Future<T?> showNexoraSheet<T>(
  BuildContext context, {
  required Widget Function(BuildContext context) builder,
  bool scrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: scrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => _NexoraSheetContent(
      scrollControlled: scrollControlled,
      child: builder(context),
    ),
  );
}

class _NexoraSheetContent extends StatelessWidget {
  const _NexoraSheetContent({required this.child, required this.scrollControlled});

  final Widget child;
  final bool scrollControlled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight)
                .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 6),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comments sheet
// ---------------------------------------------------------------------------

/// Comment thread for a post, backed by the feed provider.
class CommentsSheet extends ConsumerStatefulWidget {
  const CommentsSheet({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Load comments from the API when the sheet opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(feedProvider.notifier).openComments(widget.postId);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _postComment() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(feedProvider.notifier).addComment(widget.postId, text);
    _controller.clear();
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentUser = ref.watch(authProvider.select((s) => s.user));
    final comments = ref.watch(
      feedProvider.select((s) => s.comments[widget.postId] ?? const <Comment>[]),
    );

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
            child: Row(
              children: [
                Text(
                  'Comments',
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
            child: comments.isEmpty
                ? const _NoComments()
                : ListView.separated(
                    controller: _scroll,
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          NexoraAvatar(
                            imageUrl: comment.author.avatarUrl,
                            fallbackText: comment.author.username,
                            size: 36,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        comment.author.username,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    TrustBadge(
                                      label: comment.author.effectiveTrustLabel,
                                      compact: true,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(comment.text, style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${comment.likes} likes',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Reply',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                NexoraAvatar(
                  imageUrl: currentUser?.avatarUrl,
                  fallbackText: currentUser?.username,
                  size: 36,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _postComment(),
                    decoration: const InputDecoration(
                      hintText: 'Add a comment…',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
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

class _NoComments extends StatelessWidget {
  const _NoComments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 10),
          Text(
            'No comments yet',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start the conversation ✨',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Share sheet
// ---------------------------------------------------------------------------

/// Shareable payload for a post or reel (both map to a real post document).
class SharePayload {
  const SharePayload({required this.postId, required this.caption});

  final String postId;
  final String caption;

  String get link => 'https://nexora.app/p/$postId';
}

/// Opens the share sheet for a post.
Future<void> showShareSheet(BuildContext context, Post post) {
  return showNexoraSheet<void>(
    context,
    builder: (context) => _ShareSheetContent(
      title: 'Share this post',
      payload: SharePayload(postId: post.id, caption: post.caption),
    ),
  ).then((_) => null);
}

/// Opens the share sheet for a reel (reels map to real posts).
Future<void> showReelShareSheet(BuildContext context, String reelId,
    String caption) {
  return showNexoraSheet<void>(
    context,
    builder: (context) => _ShareSheetContent(
      title: 'Share reel',
      payload: SharePayload(postId: reelId, caption: caption),
    ),
  ).then((_) => null);
}

class _ShareSheetContent extends ConsumerStatefulWidget {
  const _ShareSheetContent({required this.title, required this.payload});

  final String title;
  final SharePayload payload;

  @override
  ConsumerState<_ShareSheetContent> createState() => _ShareSheetContentState();
}

class _ShareSheetContentState extends ConsumerState<_ShareSheetContent> {
  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.payload.link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard 🔗'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Share via DM: pick a conversation and send the post link as a real
  /// chat message through the API.
  Future<void> _shareViaDm(BuildContext context) async {
    await showNexoraSheet<void>(
      context,
      builder: (_) => _DmPickerSheet(payload: widget.payload),
      scrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShareTarget(
                icon: Icons.link_rounded,
                label: 'Copy link',
                color: AppColors.brand,
                onTap: () => _copyLink(context),
              ),
              _ShareTarget(
                icon: Icons.chat_rounded,
                label: 'Nexora DM',
                color: AppColors.accentCyan,
                onTap: () => _shareViaDm(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sharing builds community. Only members with a Trust Score above 40 can reshare content.',
            style: TextStyle(
              fontSize: 12.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Conversation picker that shares a post link via a real chat message.
class _DmPickerSheet extends ConsumerWidget {
  const _DmPickerSheet({required this.payload});

  final SharePayload payload;

  Future<void> _send(BuildContext context, WidgetRef ref, String chatId) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final sent = await ref.read(chatsProvider.notifier).sendMessage(
          chatId,
          '${payload.link}\n\n${payload.caption}',
        );
    if (!sent) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not send the message. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    navigator.pop(); // close the picker
    navigator.pop(); // close the share sheet
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sent as a DM 💬'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final chats = ref.watch(chatsProvider).chats;

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
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
                    'Share to…',
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
              child: chats.isEmpty
                  ? Center(
                      child: Text(
                        'No conversations yet.\nStart a chat first, then share here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      itemCount: chats.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ListTile(
                          leading: NexoraAvatar(
                            imageUrl: chat.participant.avatarUrl,
                            fallbackText: chat.participant.username,
                            size: 48,
                            online: chat.participant.isOnline,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  chat.participant.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TrustBadge(
                                label: chat.participant.effectiveTrustLabel,
                                compact: true,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '@${chat.participant.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _send(context, ref, chat.id),
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

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Report sheet
// ---------------------------------------------------------------------------

const List<String> _reportReasons = [
  'Spam or misleading',
  'Hate speech or harassment',
  'Violence or dangerous content',
  'Impersonation',
  'Intellectual property violation',
  'Other',
];

/// Opens the report sheet for a post (or reel) by id. Submits to
/// `POST /reports` with the real target.
Future<void> showReportSheet(BuildContext context, String postId) {
  return showNexoraSheet<void>(
    context,
    builder: (context) => _ReportContent(postId: postId),
  ).then((_) => null);
}

class _ReportContent extends ConsumerStatefulWidget {
  const _ReportContent({required this.postId});

  final String postId;

  @override
  ConsumerState<_ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends ConsumerState<_ReportContent> {
  String? _selected;
  bool _submitting = false;

  Future<void> _submit() async {
    final reason = _selected;
    if (reason == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(apiClientProvider).post('/reports', body: {
        'targetType': 'post',
        'targetId': widget.postId,
        'reason': reason,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted — thank you for keeping Nexora safe 🤝'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit the report. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Report post',
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
          Text(
            'Reports are reviewed by moderators. False reports hurt your Trust Score.',
            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          ..._reportReasons.map(
            (reason) {
              final selected = _selected == reason;
              return InkWell(
                onTap: () => setState(() => _selected = reason),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppColors.trustRed : scheme.outline,
                            width: 2,
                          ),
                          color: selected
                              ? AppColors.trustRed
                              : Colors.transparent,
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        reason,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.trustRed : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_selected == null || _submitting)
                  ? null
                  : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.flag_rounded),
              label: const Text('Submit report'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.trustRed,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
