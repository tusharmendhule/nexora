import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../../feed/data/models.dart';
import '../../reels/data/models.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.userId});

  final String? userId;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (mounted) ref.read(profileProvider.notifier).load(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final profile = ref.watch(profileProvider);
    final user = profile.user;

    if (profile.isLoading || user == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SkeletonBox(width: 32, height: 32),
                    SizedBox(width: 12),
                    SkeletonBox(width: 120, height: 18),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SkeletonBox(height: 180, radius: BorderRadius.circular(20)),
              ),
              const SizedBox(height: 8),
              const GridSkeleton(items: 9),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: DefaultTabController(
          length: 3,
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  user: user,
                  isMe: profile.isMe,
                  onEdit: () => context.push(Routes.editProfile),
                  onFollow: () => ref.read(profileProvider.notifier).toggleFollow(),
                  onMessage: () {
                    if (!profile.isMe) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Messaging opens in the DMs 💬'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  onTrust: () => context.push(Routes.trustCenter),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                _MediaGrid(posts: profile.posts),
                _ReelGrid(reels: profile.reels),
                profile.saved.isEmpty
                    ? const EmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: 'No saved posts yet',
                        subtitle: 'Bookmark posts you want to keep.',
                      )
                    : _MediaGrid(posts: profile.saved),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.isMe,
    required this.onEdit,
    required this.onFollow,
    required this.onMessage,
    required this.onTrust,
  });

  final User user;
  final bool isMe;
  final VoidCallback onEdit;
  final VoidCallback onFollow;
  final VoidCallback onMessage;
  final VoidCallback onTrust;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = user.effectiveTrustLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Cover ------------------------------------------------------
        SizedBox(
          height: 170,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              user.coverUrl == null
                  ? Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.faded(AppColors.brandGradientDeep, 0.55),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: user.coverUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.faded(AppColors.brandGradientDeep, 0.55),
                        ),
                      ),
                    ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black45],
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield_rounded, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        '${user.trustScore.round()} Trust Score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar overlapping the cover
              Transform.translate(
                offset: const Offset(0, -36),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NexoraAvatar(
                      imageUrl: user.avatarUrl,
                      fallbackText: user.username,
                      size: 88,
                      online: user.isOnline,
                    ),
                    if (user.isAiVerified)
                      Positioned(
                        right: -2,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.accentCyan,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.4,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TrustBadge(label: label),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(user.bio, style: const TextStyle(fontSize: 13.5, height: 1.4)),
                    ],
                    if (user.location.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.place_outlined, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            user.location,
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                          if (user.link.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.link_rounded, size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              user.link,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        StatCounter(value: user.posts, label: 'Posts'),
                        StatCounter(value: user.followers, label: 'Followers'),
                        StatCounter(value: user.following, label: 'Following'),
                        StatCounter(value: user.reels, label: 'Reels'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (isMe)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onEdit,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text('Edit profile'),
                            ),
                          )
                        else ...[
                          Expanded(
                            flex: 3,
                            child: PrimaryButton(
                              label: user.isFollowing ? 'Following' : 'Follow',
                              expanded: true,
                              onPressed: onFollow,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: OutlinedButton(
                              onPressed: onMessage,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Message'),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Trust snapshot card
                    GestureDetector(
                      onTap: onTrust,
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        borderRadius: BorderRadius.circular(18),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: label.color.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(Icons.shield_rounded, color: label.color, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${label.label} member',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    label.description,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: scheme.outline),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Achievements
                    if (user.achievements.isNotEmpty) ...[
                      SizedBox(
                        height: 64,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: user.achievements.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final achievement = user.achievements[index];
                            return Column(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.faded(AppColors.brandGradient, 0.18),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.brand.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Icon(achievement.icon, size: 20, color: scheme.primary),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width: 62,
                                  child: Text(
                                    achievement.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Tabs
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        tabs: const [
                          Tab(icon: Icon(Icons.grid_view_rounded, size: 20)),
                          Tab(icon: Icon(Icons.play_circle_outline_rounded, size: 20)),
                          Tab(icon: Icon(Icons.bookmark_border_rounded, size: 20)),
                        ],
                        indicator: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: post.isVideo ? post.videoUrl! : post.images.first,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            if (post.isVideo)
              const Positioned(
                right: 6,
                bottom: 6,
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
              )
            else if (post.isCarousel)
              const Positioned(
                right: 6,
                top: 6,
                child: Icon(Icons.collections_rounded, color: Colors.white, size: 16),
              ),
          ],
        );
      },
    );
  }
}

class _ReelGrid extends StatelessWidget {
  const _ReelGrid({required this.reels});

  final List<Reel> reels;

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) {
      return const EmptyState(
        icon: Icons.play_circle_outline_rounded,
        title: 'No reels yet',
        subtitle: 'Your vertical videos will appear here.',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final reel = reels[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: reel.videoUrl,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const Positioned(
              right: 6,
              bottom: 6,
              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 22),
            ),
            Positioned(
              left: 6,
              bottom: 6,
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.white, size: 13),
                  const SizedBox(width: 3),
                  Text(
                    Formatters.compactCount(reel.likes),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
