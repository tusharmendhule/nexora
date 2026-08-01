import 'package:http/http.dart' as http;

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

/// Repository interface for authentication.
///
/// Backed by [ApiAuthRepository], which talks to the Nexora API's built-in
/// email/password auth (users stored in MongoDB, Nexora JWT sessions).
abstract interface class AuthRepository {
  Future<User> signInWithEmail(String email, String password);

  Future<User> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  Future<User> signInAsGuest();

  Future<void> signOut();

  Future<User> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? link,
    String? avatarUrl,
  });

  /// Uploads new avatar bytes to Cloudinary and returns the updated profile.
  Future<User> uploadAvatar(List<int> bytes, {String filename = 'avatar.jpg'});
}

/// Real implementation backed by the Nexora API.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  Future<User> _userFrom(Map<String, dynamic> json) {
    final token = json['token'];
    final userJson = json['user'];
    if (token is! String || userJson is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from the server');
    }
    _api.token = token;
    return Future.value(User.fromApi(userJson));
  }

  @override
  Future<User> signInWithEmail(String email, String password) async {
    final json = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _userFrom(json as Map<String, dynamic>);
  }

  @override
  Future<User> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    final json = await _api.post('/auth/register', body: {
      'name': name,
      'username': username,
      'email': email,
      'password': password,
    });
    return _userFrom(json as Map<String, dynamic>);
  }

  @override
  Future<User> signInAsGuest() async {
    final json = await _api.post('/auth/guest');
    return _userFrom(json as Map<String, dynamic>);
  }

  @override
  Future<void> signOut() async {
    _api.token = null;
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? link,
    String? avatarUrl,
  }) async {
    final json = await _api.patch('/auth/me', body: {
      if (name != null) 'name': name,
      if (username != null) 'username': username,
      if (bio != null) 'bio': bio,
      if (location != null) 'location': location,
      if (link != null) 'link': link,
      if (avatarUrl != null && avatarUrl.startsWith('http')) 'avatar': avatarUrl,
    });
    final userJson = (json as Map<String, dynamic>)['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from the server');
    }
    return User.fromApi(userJson);
  }

  @override
  Future<User> uploadAvatar(List<int> bytes, {String filename = 'avatar.jpg'}) async {
    final json = await _api.postMultipart(
      '/auth/avatar',
      files: [
        http.MultipartFile.fromBytes('avatar', bytes, filename: filename),
      ],
    );
    final userJson = (json as Map<String, dynamic>)['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from the server');
    }
    return User.fromApi(userJson);
  }
}
