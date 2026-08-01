import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/models.dart';
import '../data/post_repository.dart';

/// API-backed feed repository.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return ApiPostRepository(ref.watch(apiClientProvider));
});

/// Feed UI state.
class FeedState {
  const FeedState({
    this.posts = const [],
    this.stories = const [],
    this.comments = const {},
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.cursor,
    this.error,
  });

  final List<Post> posts;
  final List<Story> stories;
  final Map<String, List<Comment>> comments;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? cursor;
  final String? error;

  FeedState copyWith({
    List<Post>? posts,
    List<Story>? stories,
    Map<String, List<Comment>>? comments,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? cursor,
    String? error,
    bool clearError = false,
  }) {
    return FeedState(
      posts: posts ?? this.posts,
      stories: stories ?? this.stories,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FeedNotifier extends Notifier<FeedState> {
  late final PostRepository _repository = ref.watch(postRepositoryProvider);

  @override
  FeedState build() {
    Future<void>.microtask(_loadInitial);
    return const FeedState();
  }

  Future<void> _loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await Future.wait([
        _repository.fetchFeed(page: 0),
        _repository.fetchStories(),
      ]);
      final posts = results[0] as List<Post>;
      final stories = results[1] as List<Story>;
      state = state.copyWith(
        posts: posts,
        stories: stories,
        isLoading: false,
        hasMore: posts.length >= 20,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not reach the feed. Check your connection.',
      );
    }
  }

  Future<void> refresh() => _loadInitial();

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final last = state.posts.isEmpty ? null : state.posts.last.createdAt;
      final more = await _repository.fetchFeed(page: 0, cursor: last?.toIso8601String());
      if (more.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
        return;
      }
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoadingMore: false,
        hasMore: more.length >= 20,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false, hasMore: false);
    }
  }

  /// Prepend a freshly published post to the top of the feed.
  void addPost(Post post) {
    state = state.copyWith(posts: [post, ...state.posts]);
  }

  Future<void> toggleLike(String postId) async {
    final wasLiked = state.posts.where((p) => p.id == postId).firstOrNull?.isLiked;
    state = state.copyWith(
      posts: [
        for (final post in state.posts)
          if (post.id == postId)
            post.copyWith(
              isLiked: !post.isLiked,
              likes: post.likes + (post.isLiked ? -1 : 1),
            )
          else
            post,
      ],
    );
    try {
      await _repository.toggleLike(postId);
    } catch (_) {
      // Revert on failure.
      state = state.copyWith(
        posts: [
          for (final post in state.posts)
            if (post.id == postId && wasLiked != null)
              post.copyWith(isLiked: wasLiked, likes: post.likes + (wasLiked ? 1 : -1))
            else
              post,
        ],
      );
    }
  }

  Future<void> toggleBookmark(String postId) async {
    state = state.copyWith(
      posts: [
        for (final post in state.posts)
          if (post.id == postId)
            post.copyWith(isBookmarked: !post.isBookmarked)
          else
            post,
      ],
    );
    try {
      await _repository.toggleBookmark(postId);
    } catch (_) {
      state = state.copyWith(
        posts: [
          for (final post in state.posts)
            if (post.id == postId) post.copyWith(isBookmarked: !post.isBookmarked) else post,
        ],
      );
    }
  }

  Future<void> openComments(String postId) async {
    if (state.comments.containsKey(postId)) return;
    try {
      final comments = await _repository.fetchComments(postId);
      state = state.copyWith(
        comments: {...state.comments, postId: comments},
      );
    } catch (_) {/* ignore */}
  }

  Future<void> addComment(String postId, String text) async {
    try {
      final comment = await _repository.addComment(postId, text);
      final comments = Map<String, List<Comment>>.from(state.comments);
      comments[postId] = [comment, ...?comments[postId]];
      state = state.copyWith(
        comments: comments,
        posts: [
          for (final post in state.posts)
            if (post.id == postId) post.copyWith(comments: post.comments + 1) else post,
        ],
      );
    } catch (_) {/* surface via UI later */}
  }

  void markStorySeen(String storyId) {
    state = state.copyWith(
      stories: [
        for (final story in state.stories)
          if (story.id == storyId)
            Story(
              id: story.id,
              user: story.user,
              imageUrl: story.imageUrl,
              caption: story.caption,
              isSeen: true,
              isMine: story.isMine,
            )
          else
            story,
      ],
    );
  }

  /// Uploads a new story (image → Cloudinary) and refreshes the tray.
  Future<Story?> createStory(List<int> bytes, {String caption = ''}) async {
    try {
      final story = await _repository.createStory(bytes, caption: caption);
      state = state.copyWith(stories: [story, ...state.stories]);
      return story;
    } catch (_) {
      return null;
    }
  }
}

final feedProvider = NotifierProvider<FeedNotifier, FeedState>(FeedNotifier.new);
