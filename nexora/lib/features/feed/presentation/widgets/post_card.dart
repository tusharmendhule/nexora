import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../../shared/widgets/bottom_sheets.dart';
import '../../../../shared/widgets/common.dart';
import '../../../../shared/widgets/like_heart.dart';
import '../../../../shared/widgets/trust_widgets.dart';
import '../../data/models.dart';
import '../feed_providers.dart';
import 'post_carousel.dart';
import 'post_video_widget.dart';

/// A single feed post with full interaction set:
/// like, comment, share, bookmark, report and double-tap-to-like.
class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  int _heartTrigger = 0;

  Post get post => widget.post;

  void _doubleTapLike() {
    if (!post.isLiked) {
      ref.read(feedProvider.notifier).toggleLike(post.id);
    }
    setState(() => _heartTrigger++);
  }

  void _openComments() {
    showNexoraSheet(
      context,
      builder: (_) => CommentsSheet(postId: post.id),
      scrollControlled: true,
    );
  }

  void _toggleLike() => ref.read(feedProvider.notifier).toggleLike(post.id);

  void _toggleBookmark() =>
      ref.read(feedProvider.notifier).toggleBookmark(post.id);

  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.flag_rounded,
              label: 'Report post',
              color: Colors.redAccent,
              onTap: () {
                Navigator.of(sheetContext).pop();
                showReportSheet(context, post);
              },
            ),
            _MenuTile(
              icon: Icons.person_add_alt_1_rounded,
              label: post.author.isFollowing ? 'Unfollow @${post.author.username}' : 'Follow @${post.author.username}',
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            _MenuTile(
              icon: Icons.link_rounded,
              label: 'Copy link',
              onTap: () {
                Navigator.of(sheetContext).pop();
                Clipboard.setData(
                  ClipboardData(text: 'https://nexora.app/p/${post.id}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Link copied to clipboard 🔗'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _MenuTile(
              icon: Icons.block_rounded,
              label: 'Block @${post.author.username}',
              color: Colors.redAccent,
              onTap: () => Navigator.of(sheetContext).pop(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Header -----------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              NexoraAvatar(
                imageUrl: post.author.avatarUrl,
                fallbackText: post.author.username,
                size: 40,
                online: post.author.isOnline,
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
                            post.author.username,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TrustBadge(
                          label: post.author.effectiveTrustLabel,
                          compact: true,
                        ),
                        if (post.isAiVerified) ...[
                          const SizedBox(width: 5),
                          const VerifiedBadge(compact: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (post.location != null) ...[
                          Icon(Icons.place_rounded,
                              size: 12, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              post.location!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          Formatters.timeAgo(post.createdAt),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _openMenu,
                icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // ---- Media ------------------------------------------------------
        Stack(
          alignment: Alignment.center,
          children: [
            if (post.isVideo)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: PostVideo(
                  url: post.videoUrl!,
                  autoplay: false,
                  onDoubleTap: _doubleTapLike,
                ),
              )
            else if (post.isCarousel)
              PostCarousel(
                images: post.images,
                onDoubleTap: _doubleTapLike,
              )
            else
              GestureDetector(
                onDoubleTap: _doubleTapLike,
                child: CachedNetworkImage(
                  imageUrl: post.images.first,
                  width: double.infinity,
                  height: 420,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 420,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_rounded),
                  ),
                ),
              ),
            LikeHeart(trigger: _heartTrigger),
          ],
        ),

        // ---- Actions ----------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: Row(
            children: [
              _ActionIcon(
                icon: post.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: post.isLiked ? Colors.redAccent : null,
                onTap: _toggleLike,
              ),
              _ActionIcon(
                icon: Icons.chat_bubble_outline_rounded,
                onTap: _openComments,
              ),
              _ActionIcon(
                icon: Icons.send_rounded,
                onTap: () => showShareSheet(context, post),
              ),
              const Spacer(),
              _ActionIcon(
                icon: post.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: post.isBookmarked ? scheme.primary : null,
                onTap: _toggleBookmark,
              ),
            ],
          ),
        ),

        // ---- Likes + caption --------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post-level AI trust verdict: score + colour label + fact-check.
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TrustVerdict(trust: post.trust),
              ),
              Text(
                '${Formatters.compactCount(post.likes)} likes',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              const SizedBox(height: 4),
              _PostCaption(caption: post.caption, author: post.author.username),
              const SizedBox(height: 4),
              if (post.comments > 0)
                GestureDetector(
                  onTap: _openComments,
                  child: Text(
                    'View all ${post.comments} comments',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                Formatters.timeAgo(post.createdAt).toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 0.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, this.onTap, this.color});

  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 26, color: color),
    );
  }
}

/// The AI trust verdict chip for a single post: score + colour label +
/// fact-check summary from the real analysis pipeline. Shows a pending
/// state while the background analysis is still running.
class _TrustVerdict extends StatelessWidget {
  const _TrustVerdict({required this.trust});

  final TrustInfo? trust;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (trust == null || trust!.status == 'pending') {
      const pendingColor = AppColors.trustOrange;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: pendingColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pendingColor.withValues(alpha: 0.4)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.trustOrange,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'AI fact-check in progress…',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.trustOrange,
              ),
            ),
          ],
        ),
      );
    }

    final label = trust!.trustLabel;
    final color = label.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_rounded, size: 17, color: color),
          const SizedBox(width: 8),
          Text(
            '${trust!.score.round()} Trust',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              label.label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              trust!.factChecks.isNotEmpty
                  ? (trust!.factChecks.first['summary'] as String? ??
                      'Checked by AI')
                  : (trust!.factors.isNotEmpty
                      ? 'Analysed by AI'
                      : 'AI verified'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a caption with highlighted hashtags and mentions.
class _PostCaption extends StatelessWidget {
  const _PostCaption({required this.caption, required this.author});

  final String caption;
  final String author;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final spans = <TextSpan>[
      TextSpan(
        text: '$author ',
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
      ),
    ];

    for (final word in caption.split(' ')) {
      if (word.startsWith('#')) {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
            fontSize: 13.5,
          ),
        ));
      } else if (word.startsWith('@')) {
        spans.add(TextSpan(
          text: '$word ',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF22D3EE),
            fontSize: 13.5,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: '$word ',
          style: TextStyle(fontSize: 13.5, color: scheme.onSurface),
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 4,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }
}
