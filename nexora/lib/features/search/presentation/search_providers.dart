import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../feed/data/models.dart';

class SearchResults {
  const SearchResults({
    this.people = const [],
    this.posts = const [],
    this.tags = const [],
    this.isLoading = false,
  });

  final List<User> people;
  final List<Post> posts;
  final List<String> tags;
  final bool isLoading;

  SearchResults copyWith({
    List<User>? people,
    List<Post>? posts,
    List<String>? tags,
    bool? isLoading,
  }) {
    return SearchResults(
      people: people ?? this.people,
      posts: posts ?? this.posts,
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends Notifier<SearchResults> {
  @override
  SearchResults build() => const SearchResults();

  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const SearchResults();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final json = await ref
          .watch(apiClientProvider)
          .get('/users/search', query: {'q': q});
      final data = (json as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
      final people = (data?['people'] as List?)
              ?.map((u) => User.fromApi(u as Map<String, dynamic>))
              .toList() ??
          const <User>[];
      final posts = (data?['posts'] as List?)
              ?.map((p) => Post.fromApi(p as Map<String, dynamic>))
              .toList() ??
          const <Post>[];
      final tags = (data?['tags'] as List?)?.cast<String>() ?? const [];
      state = SearchResults(people: people, posts: posts, tags: tags, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchResults>(SearchNotifier.new);
