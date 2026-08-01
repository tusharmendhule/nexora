import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../feed/data/models.dart';
import '../../reels/data/models.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.posts = const [],
    this.reels = const [],
    this.saved = const [],
    this.isLoading = true,
    this.isFollowing = false,
    this.isMe = false,
  });

  final User? user;
  final List<Post> posts;
  final List<Reel> reels;
  final List<Post> saved;
  final bool isLoading;
  final bool isFollowing;
  final bool isMe;

  ProfileState copyWith({
    User? user,
    List<Post>? posts,
    List<Reel>? reels,
    List<Post>? saved,
    bool? isLoading,
    bool? isFollowing,
    bool? isMe,
  }) {
    return ProfileState(
      user: user ?? this.user,
      posts: posts ?? this.posts,
      reels: reels ?? this.reels,
      saved: saved ?? this.saved,
      isLoading: isLoading ?? this.isLoading,
      isFollowing: isFollowing ?? this.isFollowing,
      isMe: isMe ?? this.isMe,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  String? _selfId;

  @override
  ProfileState build() {
    _selfId = ref.read(authProvider).user?.id;
    Future<void>.microtask(_load);
    return const ProfileState();
  }

  /// Loads a profile. Pass `null` for the signed-in member.
  Future<void> _load({String? userId}) async {
    final api = ref.read(apiClientProvider);
    final id = (userId == null || userId == 'me' || userId == 'u_me')
        ? _selfId
        : userId;
    if (id == null) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final json = await api.get('/users/$id');
      final data = json as Map<String, dynamic>;
      final userJson = (data['user'] as Map<String, dynamic>?) ?? const {};
      final user = User.fromApi(userJson);
      state = ProfileState(
        user: user,
        posts: (data['posts'] as List?)
                ?.map((p) => Post.fromApi(p as Map<String, dynamic>))
                .toList() ??
            const [],
        reels: (data['reels'] as List?)
                ?.map((r) => Reel.fromApi(r as Map<String, dynamic>))
                .toList() ??
            const [],
        saved: (data['saved'] as List?)
                ?.map((p) => Post.fromApi(p as Map<String, dynamic>))
                .toList() ??
            const [],
        isLoading: false,
        isFollowing: userJson['isFollowing'] == true,
        isMe: user.id == _selfId,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void load(String? userId) => _load(userId: userId);

  Future<void> toggleFollow() async {
    final api = ref.read(apiClientProvider);
    final user = state.user;
    if (user == null) return;
    final next = !state.isFollowing;
    state = state.copyWith(
      isFollowing: next,
      user: user.copyWith(
        isFollowing: next,
        followers: user.followers + (next ? 1 : -1),
      ),
    );
    try {
      await api.post('/users/${user.id}/follow');
    } catch (_) {
      state = state.copyWith(
        isFollowing: !next,
        user: user.copyWith(
          isFollowing: !next,
          followers: user.followers + (next ? -1 : 1),
        ),
      );
    }
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
