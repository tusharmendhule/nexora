import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../feed/data/models.dart';

/// Explore UI state.
class ExploreState {
  const ExploreState({
    this.items = const [],
    this.topics = const [],
    this.isLoading = true,
  });

  final List<Post> items;
  final List<String> topics;
  final bool isLoading;

  ExploreState copyWith({
    List<Post>? items,
    List<String>? topics,
    bool? isLoading,
  }) {
    return ExploreState(
      items: items ?? this.items,
      topics: topics ?? this.topics,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ExploreNotifier extends Notifier<ExploreState> {
  @override
  ExploreState build() {
    Future<void>.microtask(_load);
    return const ExploreState();
  }

  Future<void> _load() async {
    try {
      final json = await ref
          .watch(apiClientProvider)
          .get('/users/explore');
      final data = (json as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
      final items = (data?['items'] as List?)
              ?.map((p) => Post.fromApi(p as Map<String, dynamic>))
              .toList() ??
          const <Post>[];
      final topics = (data?['topics'] as List?)?.cast<String>() ?? const [];
      state = ExploreState(items: items, topics: topics, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => _load();
}

final exploreProvider =
    NotifierProvider<ExploreNotifier, ExploreState>(ExploreNotifier.new);
