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
    final reel = state.reels.where((r) => r.id == reelId).firstOrNull;
    if (reel == null) return;
    final wasLiked = reel.isLiked;
    state = state.copyWith(
      reels: [
        for (final r in state.reels)
          if (r.id == reelId)
            r.copyWith(
              isLiked: !r.isLiked,
              likes: r.likes + (r.isLiked ? -1 : 1),
            )
          else
            r,
      ],
    );
    try {
      await ref.watch(apiClientProvider).post('/posts/$reelId/like');
    } catch (_) {
      // Server rejected the toggle — revert so the UI matches reality.
      state = state.copyWith(
        reels: [
          for (final r in state.reels)
            if (r.id == reelId)
              r.copyWith(
                isLiked: wasLiked,
                likes: r.likes + (wasLiked ? 1 : -1),
              )
            else
              r,
        ],
      );
    }
  }

  Future<void> toggleBookmark(String reelId) async {
    final reel = state.reels.where((r) => r.id == reelId).firstOrNull;
    if (reel == null) return;
    final wasBookmarked = reel.isBookmarked;
    state = state.copyWith(
      reels: [
        for (final r in state.reels)
          if (r.id == reelId)
            r.copyWith(isBookmarked: !r.isBookmarked)
          else
            r,
      ],
    );
    try {
      await ref.watch(apiClientProvider).post('/posts/$reelId/bookmark');
    } catch (_) {
      // Server rejected the toggle — revert so the UI matches reality.
      state = state.copyWith(
        reels: [
          for (final r in state.reels)
            if (r.id == reelId)
              r.copyWith(isBookmarked: wasBookmarked)
            else
              r,
        ],
      );
    }
  }
}

final reelsProvider = NotifierProvider<ReelsNotifier, ReelsState>(ReelsNotifier.new);
