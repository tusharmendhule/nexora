import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../feed/data/models.dart';
import 'explore_providers.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final explore = ref.watch(exploreProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  Text(
                    'Explore',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => context.push(Routes.search),
                    icon: const Icon(Icons.search_rounded, size: 26),
                  ),
                ],
              ),
            ),
            Expanded(
              child: explore.isLoading && explore.items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: GridSkeleton(items: 9),
                    )
                  : explore.items.isEmpty
                      ? const EmptyState(
                          icon: Icons.explore_outlined,
                          title: 'Nothing trending yet',
                          subtitle: 'Posts from trusted creators will appear here.',
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Trending topics chips
                              SizedBox(
                                height: 40,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  children: [
                                    for (final topic in explore.topics)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: _TopicChip(label: topic),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Trending for you',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 3,
                                  crossAxisSpacing: 3,
                                ),
                                itemCount: explore.items.length,
                                itemBuilder: (context, index) {
                                  final post = explore.items[index];
                                  return _ExploreTile(post: post);
                                },
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ExploreTile extends StatelessWidget {
  const _ExploreTile({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final media = post.isVideo ? post.videoUrl : post.images.firstOrNull;
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: media ?? '',
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        ),
        if (post.isVideo)
          const Positioned(
            right: 8,
            bottom: 8,
            child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 26),
          )
        else if (post.isCarousel)
          const Positioned(
            right: 8,
            top: 8,
            child: Icon(Icons.collections_rounded, color: Colors.white, size: 18),
          ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 4),
              Text(
                _compact(post.likes),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        // Trust tint for restricted content
        if (post.author.effectiveTrustLabel.label == 'Restricted')
          Container(
            color: AppColors.trustRed.withValues(alpha: 0.35),
          ),
      ],
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
