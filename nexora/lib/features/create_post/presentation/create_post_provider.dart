import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/data/models.dart';
import '../../feed/data/post_repository.dart';
import '../../feed/presentation/feed_providers.dart';

/// Media items that can be attached to a new post.
class CreatePostState {
  const CreatePostState({
    this.media = const [],
    this.mediaBytes = const {},
    this.isVideo = false,
    this.caption = '',
    this.hashtags = const [],
    this.mentions = const [],
    this.location,
    this.isPublishing = false,
    this.published = false,
    this.error,
  });

  final List<String> media; // local paths / display refs
  final Map<String, List<int>> mediaBytes; // path → bytes for upload
  final bool isVideo;
  final String caption;
  final List<String> hashtags;
  final List<String> mentions;
  final String? location;
  final bool isPublishing;
  final bool published;
  final String? error;

  CreatePostState copyWith({
    List<String>? media,
    Map<String, List<int>>? mediaBytes,
    bool? isVideo,
    String? caption,
    List<String>? hashtags,
    List<String>? mentions,
    String? location,
    bool? isPublishing,
    bool? published,
    String? error,
    bool clearLocation = false,
    bool clearError = false,
  }) {
    return CreatePostState(
      media: media ?? this.media,
      mediaBytes: mediaBytes ?? this.mediaBytes,
      isVideo: isVideo ?? this.isVideo,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      mentions: mentions ?? this.mentions,
      location: clearLocation ? null : (location ?? this.location),
      isPublishing: isPublishing ?? this.isPublishing,
      published: published ?? this.published,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CreatePostNotifier extends Notifier<CreatePostState> {
  @override
  CreatePostState build() => const CreatePostState();

  void addMedia(String item, {bool isVideo = false, List<int>? bytes}) {
    state = state.copyWith(
      media: [...state.media, item],
      mediaBytes: {
        ...state.mediaBytes,
        if (bytes != null) item: bytes,
      },
      isVideo: isVideo || state.isVideo,
    );
  }

  void removeMediaAt(int index) {
    final media = [...state.media];
    final removed = media.removeAt(index);
    final mediaBytes = {...state.mediaBytes}..remove(removed);
    state = state.copyWith(
      media: media,
      mediaBytes: mediaBytes,
      isVideo: media.isEmpty ? false : state.isVideo,
    );
  }

  void setCaption(String value) => state = state.copyWith(caption: value);

  void addHashtag(String tag) {
    final clean = tag.replaceAll('#', '').trim();
    if (clean.isEmpty || state.hashtags.contains(clean)) return;
    state = state.copyWith(hashtags: [...state.hashtags, clean]);
  }

  void removeHashtag(String tag) {
    state = state.copyWith(hashtags: [...state.hashtags]..remove(tag));
  }

  void addMention(String mention) {
    final clean = mention.replaceAll('@', '').trim();
    if (clean.isEmpty || state.mentions.contains(clean)) return;
    state = state.copyWith(mentions: [...state.mentions, clean]);
  }

  void removeMention(String mention) {
    state = state.copyWith(mentions: [...state.mentions]..remove(mention));
  }

  void setLocation(String? value) => state = state.copyWith(location: value);

  /// Publishes via POST /posts (multipart). Returns the created Post or null.
  Future<Post?> publish() async {
    final repo = ref.read(postRepositoryProvider);
    final current = state;
    state = state.copyWith(isPublishing: true, clearError: true);
    try {
      final files = <ApiMediaFile>[];
      for (final path in current.media) {
        final bytes = current.mediaBytes[path];
        if (bytes == null || bytes.isEmpty) continue;
        final name = path.split('/').last.split('\\').last;
        files.add(ApiMediaFile(
          bytes: bytes,
          filename: name.isEmpty ? 'upload.jpg' : name,
          isVideo: current.isVideo,
        ));
      }
      if (files.isEmpty) {
        state = state.copyWith(
          isPublishing: false,
          error: 'Please attach a photo or video.',
        );
        return null;
      }

      final post = await repo.createPost(
        caption: current.caption.trim().isEmpty
            ? 'New post ✨'
            : current.caption.trim(),
        hashtags: current.hashtags,
        mentions: current.mentions,
        location: current.location,
        files: files,
      );
      state = const CreatePostState(published: true);
      ref.read(feedProvider.notifier).addPost(post);
      return post;
    } catch (e) {
      state = state.copyWith(
        isPublishing: false,
        error: 'Could not publish. Check your connection.',
      );
      return null;
    }
  }
}

final createPostProvider =
    NotifierProvider<CreatePostNotifier, CreatePostState>(CreatePostNotifier.new);
