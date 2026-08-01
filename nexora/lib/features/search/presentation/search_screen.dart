import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/user.dart';
import '../../../shared/widgets/avatar.dart';
import '../../../shared/widgets/search_bar.dart';
import '../../../shared/widgets/trust_widgets.dart';
import '../../feed/data/models.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(searchProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchProvider);
    final searching = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: NexoraSearchBar(
                controller: _controller,
                hintText: 'Search people, posts, hashtags…',
                autofocus: true,
                onChanged: _onQueryChanged,
              ),
            ),
            Expanded(
              child: DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'People'),
                        Tab(text: 'Posts'),
                        Tab(text: 'Tags'),
                      ],
                      labelStyle: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Expanded(
                      child: results.isLoading && searching
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              children: [
                                _PeopleResults(people: results.people),
                                _PostsResults(posts: results.posts),
                                _TagsResults(
                                  tags: results.tags,
                                  showSuggestion: searching,
                                ),
                              ],
                            ),
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

class _PeopleResults extends StatelessWidget {
  const _PeopleResults({required this.people});

  final List<User> people;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const Center(child: Text('No people match your search.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: people.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final user = people[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          leading: NexoraAvatar(
            imageUrl: user.avatarUrl,
            fallbackText: user.username,
            size: 46,
            online: user.isOnline,
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  user.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 6),
              TrustBadge(label: user.effectiveTrustLabel, compact: true),
            ],
          ),
          subtitle: Text('@${user.username} • ${_followers(user.followers)} followers'),
          onTap: () => context.push(Routes.profilePath(user.id)),
        );
      },
    );
  }

  String _followers(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';
}

class _PostsResults extends StatelessWidget {
  const _PostsResults({required this.posts});

  final List<Post> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Center(child: Text('No posts match your search.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return CachedNetworkImage(
          imageUrl: post.isVideo ? post.videoUrl! : post.images.first,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
        );
      },
    );
  }
}

class _TagsResults extends StatelessWidget {
  const _TagsResults({required this.tags, required this.showSuggestion});

  final List<String> tags;
  final bool showSuggestion;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (tags.isEmpty) {
      return const Center(child: Text('No hashtags match your search.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tags.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == 0 && showSuggestion) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: AppColors.brand, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Searches from verified members rank higher on Nexora.',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }
        final tag = tags[index - (showSuggestion ? 1 : 0)];
        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tag_rounded, color: AppColors.brand),
            ),
            const SizedBox(width: 12),
            Text(
              tag.startsWith('#') ? tag : '#$tag',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const Spacer(),
            Icon(
              Icons.tag_rounded,
              size: 15,
              color: scheme.onSurfaceVariant,
            ),
          ],
        );
      },
    );
  }
}
