import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Shared API client. The bearer token is stored here after sign-in.
final apiClientProvider = Provider<ApiClient>((_) => ApiClient());

/// Nexora API client backed by `package:http`.
///
/// Point [ApiClient.baseUrl] at the Express API (`/api/v1`). Tokens are sent
/// as `Authorization: Bearer <token>` when set via [token].
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : _http = httpClient ?? http.Client(),
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

  /// Bearer token attached to every request (set after sign-in).
  String? token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final res = await _http.get(uri, headers: _headers);
    return _decode(res);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _http.post(
      uri,
      headers: {..._headers, ...?headers},
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res);
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _http.patch(
      uri,
      headers: _headers,
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final res = await _http.delete(uri, headers: _headers);
    return _decode(res);
  }

  /// Multipart POST for media uploads (Cloudinary via the API).
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<http.MultipartFile>? files,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
      })
      ..fields.addAll(fields);
    if (files != null) request.files.addAll(files);
    final streamed = await _http.send(request);
    final res = await http.Response.fromStream(streamed);
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
