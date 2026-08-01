import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/models.dart';

class ReelsState {
  const ReelsState({this.reels = const [], this.isLoading = true, this.currentIndex = 0});

  final List<Reel> reels;
  final bool isLoading;
  final int currentIndex;

  ReelsState copyWith({
    List<Reel>? reels,
    bool? isLoading,
    int? currentIndex,
  }) {
    return ReelsState(
      reels: reels ?? this.reels,
      isLoading: isLoading ?? this.isLoading,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class ReelsNotifier extends Notifier<ReelsState> {
  @override
  ReelsState build() {
    Future<void>.microtask(_load);
    return const ReelsState();
  }

  Future<void> _load() async {
    try {
      final json = await ref.watch(apiClientProvider).get('/users/reels');
      final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
      state = ReelsState(
        reels: data.map((r) => Reel.fromApi(r as Map<String, dynamic>)).toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setIndex(int index) => state = state.copyWith(currentIndex: index);

  Future<void> toggleLike(String reelId) async {
    state = state.copyWith(
      reels: [
        for (final reel in state.reels)
          if (reel.id == reelId)
            reel.copyWith(
              isLiked: !reel.isLiked,
              likes: reel.likes + (reel.isLiked ? -1 : 1),
            )
          else
            reel,
      ],
    );
    try {
      await ref.watch(apiClientProvider).post('/posts/$reelId/like');
    } catch (_) {/* ignore */}
  }

  Future<void> toggleBookmark(String reelId) async {
    state = state.copyWith(
      reels: [
        for (final reel in state.reels)
          if (reel.id == reelId)
            reel.copyWith(isBookmarked: !reel.isBookmarked)
          else
            reel,
      ],
    );
    try {
      await ref.watch(apiClientProvider).post('/posts/$reelId/bookmark');
    } catch (_) {/* ignore */}
  }
}

final reelsProvider = NotifierProvider<ReelsNotifier, ReelsState>(ReelsNotifier.new);
