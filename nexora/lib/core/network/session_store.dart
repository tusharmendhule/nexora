import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists the auth session (access token, refresh token, user JSON) so the
/// user stays signed in across app restarts instead of being forced back
/// through onboarding + login every launch.
class SessionStore {
  static const _tokenKey = 'auth_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userKey = 'auth_user_json';

  /// Save (or update) the session. Pass `user: null` to only refresh tokens.
  Future<void> saveSession({
    required String token,
    required String? refreshToken,
    Map<String, dynamic>? user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshKey, refreshToken);
    }
    if (user != null) {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  Future<({String? token, String? refreshToken, Map<String, dynamic>? user})>
      loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUser = prefs.getString(_userKey);
    return (
      token: prefs.getString(_tokenKey),
      refreshToken: prefs.getString(_refreshKey),
      user: rawUser == null
          ? null
          : jsonDecode(rawUser) as Map<String, dynamic>,
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userKey);
  }
}
