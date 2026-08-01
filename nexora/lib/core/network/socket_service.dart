import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/chat/presentation/chats_providers.dart';
import '../../features/notifications/presentation/notifications_providers.dart';
import 'api_client.dart';

/// Real-time gateway. Connects once with the access JWT and fans Socket.IO
/// events out to the chat + notifications notifiers so the UI updates live.
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class SocketService {
  SocketService(this._ref);

  final Ref _ref;
  io.Socket? _socket;

  /// ws:// base derived from the HTTP API base URL.
  static String get _wsBase {
    final httpBase = ApiClient.defaultBaseUrl; // e.g. http://localhost:4000/api/v1
    final uri = Uri.parse(httpBase);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}:${uri.port}';
  }

  bool get isConnected => _socket?.connected ?? false;

  /// Connect with the current bearer token. Safe to call repeatedly.
  void connect() {
    final token = _ref.read(apiClientProvider).token;
    if (token == null || token.isEmpty || isConnected) return;

    _socket = io.io(
      _wsBase,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.on('connect', (_) {
      debugPrint('[socket] connected');
    });
    _socket!.on('connect_error', (err) {
      debugPrint('[socket] connect_error: $err');
    });
    _socket!.on('disconnect', (_) {
      debugPrint('[socket] disconnected');
    });

    _socket!.on('notify:new', (payload) {
      _handleNotify(payload);
    });
    _socket!.on('chat:message', (payload) {
      _handleChatMessage(payload);
    });
    _socket!.on('chat:conversation', (payload) {
      _handleConversation(payload);
    });
  }

  void _handleNotify(dynamic payload) {
    if (payload is! Map<String, dynamic>) return;
    final notifier = _ref.read(notificationsProvider.notifier);
    notifier.ingestIncoming(payload);
  }

  void _handleChatMessage(dynamic payload) {
    if (payload is! Map<String, dynamic>) return;
    final notifier = _ref.read(chatsProvider.notifier);
    notifier.ingestIncomingMessage(payload);
  }

  void _handleConversation(dynamic payload) {
    if (payload is! Map<String, dynamic>) return;
    final notifier = _ref.read(chatsProvider.notifier);
    notifier.ingestConversation(payload);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
  }
}
