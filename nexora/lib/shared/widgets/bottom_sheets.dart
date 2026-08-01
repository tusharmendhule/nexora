import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../features/auth/presentation/auth_provider.dart';
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

/// Opens the share sheet for a post.
Future<void> showShareSheet(BuildContext context, Post post) {
  return showNexoraSheet<void>(
    context,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share this post',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ShareTarget(icon: Icons.link_rounded, label: 'Copy link', color: AppColors.brand),
              _ShareTarget(icon: Icons.chat_rounded, label: 'Nexora DM', color: AppColors.accentCyan),
              _ShareTarget(icon: Icons.telegram_rounded, label: 'Telegram', color: AppColors.trustBlue),
              _ShareTarget(icon: Icons.camera_alt_rounded, label: 'Stories', color: AppColors.trustPurple),
              _ShareTarget(icon: Icons.more_horiz_rounded, label: 'More', color: AppColors.trustOrange),
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
    ),
  ).then((_) => null);
}

class _ShareTarget extends StatelessWidget {
  const _ShareTarget({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
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

/// Opens the report sheet for a post. Submits to `POST /reports`.
Future<void> showReportSheet(BuildContext context, Post post) {
  return showNexoraSheet<void>(
    context,
    builder: (context) => _ReportContent(postId: post.id),
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
            (reason) => RadioListTile<String>(
              value: reason,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              title: Text(reason, style: const TextStyle(fontSize: 14)),
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.trustRed,
            ),
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
