import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import 'models.dart';

/// Repository contract for the home feed, backed by the Nexora API.
abstract interface class PostRepository {
  Future<List<Post>> fetchFeed({required int page, String? cursor});
  Future<List<Story>> fetchStories();
  Future<List<Comment>> fetchComments(String postId);
  Future<Comment> addComment(String postId, String text);
  Future<bool> toggleLike(String postId);
  Future<bool> toggleBookmark(String postId);
  Future<Post> createPost({
    required String caption,
    required List<String> hashtags,
    required List<String> mentions,
    String? location,
    List<ApiMediaFile>? files,
  });
  Future<Story> createStory(List<int> bytes, {String caption = ''});
}

/// A media file (path or bytes) to upload with a new post.
class ApiMediaFile {
  const ApiMediaFile({required this.bytes, required this.filename, this.isVideo = false});

  final List<int> bytes;
  final String filename;
  final bool isVideo;
}

class ApiPostRepository implements PostRepository {
  ApiPostRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<Post>> fetchFeed({required int page, String? cursor}) async {
    final json = await _api.get('/feed', query: {
      'limit': '20',
      if (cursor != null) 'cursor': cursor,
    });
    final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
    return data.map((p) => Post.fromApi(p as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Story>> fetchStories() async {
    final json = await _api.get('/feed/stories');
    final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
    return data.map((s) => Story.fromApi(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<Story> createStory(List<int> bytes, {String caption = ''}) async {
    final json = await _api.postMultipart(
      '/feed/stories',
      fields: {'caption': caption},
      files: [
        http.MultipartFile.fromBytes('image', bytes,
            filename: 'story.jpg'),
      ],
    );
    final story = (json as Map<String, dynamic>?)?['story'] as Map<String, dynamic>?;
    return Story.fromApi(story ?? const {});
  }

  @override
  Future<List<Comment>> fetchComments(String postId) async {
    final json = await _api.get('/posts/$postId/comments');
    final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
    return data.map((c) => Comment.fromApi(c as Map<String, dynamic>)).toList();
  }

  @override
  Future<Comment> addComment(String postId, String text) async {
    final json = await _api.post('/posts/$postId/comments', body: {'text': text});
    final comment =
        (json as Map<String, dynamic>?)?['comment'] as Map<String, dynamic>?;
    return Comment.fromApi(comment ?? const {});
  }

  @override
  Future<bool> toggleLike(String postId) async {
    final json = await _api.post('/posts/$postId/like');
    return (json as Map<String, dynamic>?)?['liked'] == true;
  }

  @override
  Future<bool> toggleBookmark(String postId) async {
    final json = await _api.post('/posts/$postId/bookmark');
    return (json as Map<String, dynamic>?)?['bookmarked'] == true;
  }

  @override
  Future<Post> createPost({
    required String caption,
    required List<String> hashtags,
    required List<String> mentions,
    String? location,
    List<ApiMediaFile>? files,
  }) async {
    final json = await _api.postMultipart(
      '/posts',
      fields: {
        'caption': caption,
        'hashtags': hashtags.join(','),
        'mentions': mentions.join(','),
        if (location != null) 'location': location,
      },
      files: [
        for (final f in files ?? const <ApiMediaFile>[])
          http.MultipartFile.fromBytes('media', f.bytes, filename: f.filename),
      ],
    );
    final post = (json as Map<String, dynamic>?)?['post'] as Map<String, dynamic>?;
    return Post.fromApi(post ?? const {});
  }
}
