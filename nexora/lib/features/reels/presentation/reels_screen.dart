import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/bottom_sheets.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/like_heart.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../data/models.dart';
import 'reels_providers.dart';
import 'widgets/reel_player.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _controller = PageController();
  int _heartTrigger = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Reel? get _current {
    final reels = ref.read(reelsProvider).reels;
    final index = ref.read(reelsProvider).currentIndex;
    if (reels.isEmpty || index >= reels.length) return null;
    return reels[index];
  }

  void _doubleTapLike() {
    final reel = _current;
    if (reel == null) return;
    if (!reel.isLiked) ref.read(reelsProvider.notifier).toggleLike(reel.id);
    setState(() => _heartTrigger++);
  }

  void _openShareSheet(Reel reel) {
    showNexoraSheet(
      context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share reel',
              style: Theme.of(sheetContext)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SharePill(icon: Icons.link_rounded, label: 'Copy link', color: AppColors.brand),
                _SharePill(icon: Icons.chat_rounded, label: 'Nexora DM', color: AppColors.accentCyan),
                _SharePill(icon: Icons.telegram_rounded, label: 'Telegram', color: AppColors.trustBlue),
                _SharePill(icon: Icons.camera_alt_rounded, label: 'Stories', color: AppColors.trustPurple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reelsState = ref.watch(reelsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: reelsState.isLoading && reelsState.reels.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            )
          : Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  scrollDirection: Axis.vertical,
                  itemCount: reelsState.reels.length,
                  onPageChanged: (i) =>
                      ref.read(reelsProvider.notifier).setIndex(i),
                  itemBuilder: (context, index) {
                    final reel = reelsState.reels[index];
                    return _ReelPage(
                      reel: reel,
                      isActive: index == reelsState.currentIndex,
                      onDoubleTap: _doubleTapLike,
                      onLike: () =>
                          ref.read(reelsProvider.notifier).toggleLike(reel.id),
                      onBookmark: () =>
                          ref.read(reelsProvider.notifier).toggleBookmark(reel.id),
                      onShare: () => _openShareSheet(reel),
                      onComment: () {
                        // Reels map to real posts, so open the same comment
                        // thread backed by GET/POST /posts/:id/comments.
                        showNexoraSheet(
                          context,
                          builder: (_) => CommentsSheet(postId: reel.id),
                          scrollControlled: true,
                        );
                      },
                    );
                  },
                ),
                // Double-tap heart overlay
                Center(
                  child: LikeHeart(
                    trigger: _heartTrigger,
                    size: 130,
                  ),
                ),
                // Top bar
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Text(
                          'Reels',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                        const Spacer(),
                        const Icon(Icons.camera_alt_outlined, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.reel,
    required this.isActive,
    required this.onDoubleTap,
    required this.onLike,
    required this.onBookmark,
    required this.onShare,
    required this.onComment,
  });

  final Reel reel;
  final bool isActive;
  final VoidCallback onDoubleTap;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ReelPlayer(url: reel.videoUrl, isActive: isActive, onDoubleTap: onDoubleTap),
        // Legibility gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.45, 1],
              colors: [Colors.black54, Colors.transparent, Colors.black87],
            ),
          ),
        ),
        // Bottom info
        Positioned(
          left: 12,
          right: 76,
          bottom: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TrustBadge(label: reel.user.effectiveTrustLabel, compact: true),
                  if (reel.user.isAiVerified) ...[
                    const SizedBox(width: 6),
                    const VerifiedBadge(compact: true),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '@${reel.user.username}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reel.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.music_note_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      reel.music ?? 'original audio',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Right action rail
        Positioned(
          right: 8,
          bottom: 24,
          child: Column(
            children: [
              NexoraAvatar(
                imageUrl: reel.user.avatarUrl,
                fallbackText: reel.user.username,
                size: 44,
                ringColor: reel.user.isAiVerified ? AppColors.accentCyan : null,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 16),
              _RailAction(
                icon: reel.isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: reel.isLiked ? Colors.redAccent : Colors.white,
                label: Formatters.compactCount(reel.likes),
                onTap: onLike,
              ),
              _RailAction(
                icon: Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                label: Formatters.compactCount(reel.comments),
                onTap: onComment,
              ),
              _RailAction(
                icon: Icons.send_rounded,
                color: Colors.white,
                label: Formatters.compactCount(reel.shares),
                onTap: onShare,
              ),
              _RailAction(
                icon: reel.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: reel.isBookmarked ? AppColors.accentCyan : Colors.white,
                label: 'Save',
                onTap: onBookmark,
              ),
              _RailAction(
                icon: Icons.more_horiz_rounded,
                color: Colors.white,
                label: '',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(icon, color: color, size: 30),
          ),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  const _SharePill({required this.icon, required this.label, required this.color});

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
