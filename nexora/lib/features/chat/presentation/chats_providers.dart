import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/models.dart';

class ChatsState {
  const ChatsState({this.chats = const [], this.isLoading = true});

  final List<Chat> chats;
  final bool isLoading;

  int get unreadTotal => chats.fold(0, (sum, c) => sum + c.unreadCount);

  ChatsState copyWith({List<Chat>? chats, bool? isLoading}) {
    return ChatsState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatsNotifier extends Notifier<ChatsState> {
  @override
  ChatsState build() {
    Future<void>.microtask(_load);
    return const ChatsState();
  }

  Future<void> _load() async {
    try {
      final json = await ref.watch(apiClientProvider).get('/chat');
      final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
      state = ChatsState(
        chats: data.map((c) => Chat.fromApi(c as Map<String, dynamic>)).toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => _load();

  Chat? chatById(String id) {
    for (final chat in state.chats) {
      if (chat.id == id) return chat;
    }
    return null;
  }

  Future<void> sendMessage(String chatId, String text) async {
    final chat = chatById(chatId);
    if (chat == null || text.trim().isEmpty) return;
    final me = ref.read(authProvider).user;
    final message = Message(
      id: 'm_${DateTime.now().millisecondsSinceEpoch}',
      senderId: me?.id ?? 'me',
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      chats: [
        for (final c in state.chats)
          if (c.id == chatId)
            Chat(
              id: c.id,
              participant: c.participant,
              messages: [...c.messages, message],
              unread: c.unread,
            )
          else
            c,
      ],
    );
    try {
      final json = await ref
          .watch(apiClientProvider)
          .post('/chat/$chatId/messages', body: {'text': text.trim()});
      final created =
          (json as Map<String, dynamic>?)?['message'] as Map<String, dynamic>?;
      if (created != null) {
        final sent = Message.fromApi(created);
        state = state.copyWith(
          chats: [
            for (final c in state.chats)
              if (c.id == chatId)
                Chat(
                  id: c.id,
                  participant: c.participant,
                  messages: [
                    for (final m in c.messages)
                      if (m.id == message.id) sent else m,
                  ],
                  unread: c.unread,
                )
              else
                c,
          ],
        );
      }
    } catch (_) {/* keep local copy */}
  }

  /// Real-time: append an incoming message pushed by the Socket.IO gateway.
  void ingestIncomingMessage(Map<String, dynamic> payload) {
    final chatId = payload['conversationId'] as String?;
    if (chatId == null) return;
    final me = ref.read(authProvider).user;
    final incoming = Message.fromApi({
      'id': payload['id'],
      'senderId': payload['senderId'],
      'text': payload['text'],
      'createdAt': payload['createdAt'],
      'isRead': payload['isRead'] == true,
    });
    final isMine = me != null && incoming.senderId == me.id;
    state = state.copyWith(
      chats: [
        for (final c in state.chats)
          if (c.id == chatId)
            Chat(
              id: c.id,
              participant: c.participant,
              messages: [
                if (c.messages.isEmpty) incoming else ...c.messages,
                if (c.messages.isNotEmpty) incoming,
              ],
              unread: isMine ? c.unread : c.unread + 1,
            )
          else
            c,
      ],
    );
  }

  /// Real-time: a brand-new conversation was created for the current user.
  void ingestConversation(Map<String, dynamic> payload) {
    final chatId = payload['conversationId'] as String?;
    if (chatId == null) return;
    if (chatById(chatId) != null) return;
    // Fetch the full list so the new conversation renders with its peer.
    _load();
  }

  Future<void> loadMessages(String chatId) async {
    try {
      final json = await ref
          .watch(apiClientProvider)
          .get('/chat/$chatId/messages');
      final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
      final messages =
          data.map((m) => Message.fromApi(m as Map<String, dynamic>)).toList();
      state = state.copyWith(
        chats: [
          for (final c in state.chats)
            if (c.id == chatId)
              Chat(
                id: c.id,
                participant: c.participant,
                messages: messages,
                unread: 0,
              )
            else
              c,
        ],
      );
    } catch (_) {/* ignore */}
  }
}

final chatsProvider = NotifierProvider<ChatsNotifier, ChatsState>(ChatsNotifier.new);
