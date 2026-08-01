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

  /// Restore the persisted session (if any). Returns null when signed out.
  Future<User?> restoreSession();

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

  /// Persist the session (token + refresh token + user) after a successful
  /// login / sign-up / guest sign-in so it survives app restarts.
  Future<User> _userFrom(Map<String, dynamic> json) {
    final token = json['token'];
    final userJson = json['user'];
    if (token is! String || userJson is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response from the server');
    }
    _api.token = token;
    _api.refreshToken = json['refreshToken'] as String?;
    _api.persistSessionWithUser(userJson);
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
  Future<User?> restoreSession() async {
    await _api.restoreSession();
    if (_api.token == null || _api.token!.isEmpty) return null;
    try {
      // Validate against the API so banned/deleted users are caught, and
      // refresh the cached user profile. If the access token is expired the
      // ApiClient transparently refreshes it first.
      final json = await _api.get('/auth/me') as Map<String, dynamic>;
      final userJson = json['user'];
      if (userJson is Map<String, dynamic>) {
        _api.persistSessionWithUser(userJson);
        return User.fromApi(userJson);
      }
    } on ApiException catch (e) {
      // Only clear the session when the refresh endpoint definitively
      // rejected it (401/400). A 401 surfacing after a network-failed refresh
      // is transient — the cached user should still be restored.
      if (e.statusCode == 401 && _api.refreshRejected) {
        await _api.clearSession();
        return null;
      }
      // Transient server error — keep the cached session.
      return _sessionUser();
    } catch (_) {
      // Offline / transient failure — restore the cached user anyway.
      final session = await _sessionUser();
      return session;
    }
    return null;
  }

  /// Read the cached user JSON directly from storage (no network).
  Future<User?> _sessionUser() async {
    // Access the shared SessionStore through a fresh load.
    final session = await _api.restoreSessionUser();
    return session == null ? null : User.fromApi(session);
  }

  @override
  Future<void> signOut() async {
    await _api.clearSession();
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
