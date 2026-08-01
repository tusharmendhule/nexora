import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'session_store.dart';

/// Shared API client. The bearer token is stored here after sign-in.
final apiClientProvider = Provider<ApiClient>((_) => ApiClient());

/// Nexora API client backed by `package:http`.
///
/// Point [ApiClient.baseUrl] at the Express API (`/api/v1`). Tokens are sent
/// as `Authorization: Bearer <token>` when set via [token].
///
/// When a request returns 401 and a refresh token is available, the client
/// silently exchanges it for a fresh access token and retries the request
/// once, so the user's session survives the 15-minute access-token lifetime.
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
    SessionStore? sessionStore,
  })  : _http = httpClient ?? http.Client(),
        _session = sessionStore ?? SessionStore(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  /// Platform-aware default: web → localhost, Android → emulator loopback.
  /// Override with `--dart-define=API_BASE_URL=http://192.168.x.x:4000/api/v1`
  /// for a physical device.
  static String get defaultBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:4000/api/v1';
    return 'http://10.0.2.2:4000/api/v1';
  }

  final String baseUrl;
  final http.Client _http;
  final SessionStore _session;

  /// Bearer token attached to every request (set after sign-in).
  String? token;

  /// Long-lived refresh token used to renew the access token on 401.
  String? refreshToken;

  /// Fired when a refresh attempt fails (session can no longer be renewed).
  /// The auth notifier uses this to sign the user out cleanly.
  void Function()? onSessionExpired;

  /// In-flight refresh so concurrent 401s share one token exchange.
  Future<bool>? _refreshFuture;

  /// True after the refresh endpoint definitively rejected the session
  /// (401/400). Used by session restore to distinguish a dead session from a
  /// transient network failure when the access token happened to be expired.
  bool refreshRejected = false;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  /// Restore a persisted session (called once at app startup).
  Future<void> restoreSession() async {
    final session = await _session.loadSession();
    token = session.token;
    refreshToken = session.refreshToken;
  }

  /// Read the cached user JSON directly from storage (no network).
  Future<Map<String, dynamic>?> restoreSessionUser() async {
    final session = await _session.loadSession();
    return session.user;
  }

  /// Persist the tokens plus the signed-in user document. Called on every
  /// login / sign-up / guest sign-in / successful restore, so it also clears
  /// a stale [refreshRejected] flag left by a previously-dead session.
  Future<void> persistSessionWithUser(Map<String, dynamic> user) async {
    if (token == null) return;
    refreshRejected = false;
    await _session.saveSession(
      token: token!,
      refreshToken: refreshToken,
      user: user,
    );
  }

  Future<void> clearSession() async {
    token = null;
    refreshToken = null;
    refreshRejected = false;
    await _session.clear();
  }

  /// Run a request, transparently refreshing the access token on a 401 and
  /// retrying once. Concurrent 401s share a single in-flight refresh.
  ///
  /// [allowRefresh] is false for the auth endpoints themselves — a
  /// wrong-password login must surface its own 401, never trigger a token
  /// exchange.
  Future<http.Response> _send(
    Future<http.Response> Function() request, {
    bool allowRefresh = true,
  }) async {
    var res = await request();
    if (res.statusCode != 401 ||
        !allowRefresh ||
        refreshToken == null ||
        refreshToken!.isEmpty) {
      return res;
    }
    final refreshed = _refreshFuture ??=
        _tryRefresh().whenComplete(() => _refreshFuture = null);
    if (await refreshed) {
      res = await request(); // retry once with the fresh token
    }
    return res;
  }

  /// Exchange the refresh token for a fresh access token. Returns true when
  /// the access token was renewed.
  ///
  /// Only a 401/400 from `/auth/refresh` counts as a definitively dead
  /// session: it fires [onSessionExpired] and sets [refreshRejected] so
  /// session restore can tell a dead session from a transient failure.
  /// Transport errors and server 5xx are transient — we return false silently
  /// so the session survives and the next request retries when the network
  /// recovers.
  Future<bool> _tryRefresh() async {
    final rt = refreshToken;
    if (rt == null || rt.isEmpty) return false;
    try {
      final uri = Uri.parse('$baseUrl/auth/refresh');
      final res = await _http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': rt}),
      );
      if (res.statusCode == 401 || res.statusCode == 400) {
        refreshRejected = true;
        onSessionExpired?.call();
        return false;
      }
      if (res.statusCode != 200) {
        return false; // transient server error — keep the session
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final newToken = data['token'] as String?;
      if (newToken == null || newToken.isEmpty) {
        refreshRejected = true;
        onSessionExpired?.call();
        return false;
      }
      token = newToken;
      final newRefresh = data['refreshToken'] as String?;
      if (newRefresh != null && newRefresh.isNotEmpty) {
        refreshToken = newRefresh; // rotation
      }
      refreshRejected = false;
      await _session.saveSession(
        token: token!,
        refreshToken: refreshToken,
      );
      return true;
    } catch (_) {
      return false; // offline / malformed response — do not sign the user out
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await _send(() => _http.get(uri, headers: _headers));
    return _decode(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _send(
      () => _http.post(
        uri,
        headers: {..._headers, ...?headers},
        body: jsonEncode(body ?? const {}),
      ),
      // Never auto-refresh on auth endpoints: a failed login must return its
      // own 401 instead of silently rotating a stored refresh token.
      allowRefresh: !path.startsWith('/auth/'),
    );
    return _decode(res);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _send(() => _http.patch(
          uri,
          headers: _headers,
          body: jsonEncode(body ?? const {}),
        ));
    return _decode(res);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _send(() => _http.put(
          uri,
          headers: _headers,
          body: jsonEncode(body ?? const {}),
        ));
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _send(() => _http.delete(uri, headers: _headers));
    return _decode(res);
  }

  /// Multipart POST for media uploads (Cloudinary via the API).
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<http.MultipartFile>? files,
  }) async {
    Future<http.Response> send() async {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
        ..headers.addAll({
          if (token != null && token!.isNotEmpty)
            'Authorization': 'Bearer $token',
        })
        ..fields.addAll(fields);
      if (files != null) request.files.addAll(files);
      final streamed = await _http.send(request);
      return http.Response.fromStream(streamed);
    }

    final res = await _send(send);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }
    final message = (decoded is Map && decoded['error'] is String)
        ? decoded['error'] as String
        : 'Request failed (${res.statusCode})';
    throw ApiException(message, statusCode: res.statusCode);
  }
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
