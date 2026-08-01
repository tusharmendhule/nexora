import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import 'feed_providers.dart';
import 'widgets/post_card.dart';
import 'widgets/story_tray.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 500) {
      ref.read(feedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HomeHeader(),
            Expanded(
              child: feed.isLoading && feed.posts.isEmpty
                  ? const _FeedSkeleton()
                  : feed.error != null && feed.posts.isEmpty
                      ? ErrorState(
                          message: feed.error!,
                          onRetry: () => ref.read(feedProvider.notifier).refresh(),
                        )
                      : RefreshIndicator(
                          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
                          child: ListView.builder(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: feed.posts.length + 2,
                            itemBuilder: (context, index) {
                              if (index == 0) return const StoryTray();
                              final postIndex = index - 1;
                              if (postIndex >= feed.posts.length) {
                                return feed.isLoadingMore
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2.5),
                                        ),
                                      )
                                    : const SizedBox(height: 32);
                              }
                              return PostCard(post: feed.posts[postIndex]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 8, 2),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Nexora',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          _HeaderAction(
            icon: Icons.search_rounded,
            onTap: () => context.push(Routes.search),
          ),
          _HeaderAction(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () => context.push(Routes.chat),
          ),
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            onTap: () => context.push(Routes.notifications),
            badge: true,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap, this.badge = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 26),
        ),
        if (badge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.trustRed,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: StorySkeleton(),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) const PostCardSkeleton(),
      ],
    );
  }
}
