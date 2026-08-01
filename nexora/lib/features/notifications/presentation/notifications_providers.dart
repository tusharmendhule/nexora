import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../data/models.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = true,
    this.tabIndex = 0,
  });

  final List<AppNotification> items;
  final bool isLoading;
  final int tabIndex;

  int get unreadCount => items.where((n) => !n.isRead).length;

  NotificationsState copyWith({
    List<AppNotification>? items,
    bool? isLoading,
    int? tabIndex,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future<void>.microtask(_load);
    return const NotificationsState();
  }

  Future<void> _load() async {
    try {
      final json = await ref.watch(apiClientProvider).get('/notifications');
      final data = (json as Map<String, dynamic>?)?['data'] as List? ?? const [];
      state = NotificationsState(
        items: data
            .map((n) => AppNotification.fromApi(n as Map<String, dynamic>))
            .toList(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setTab(int index) => state = state.copyWith(tabIndex: index);

  /// Prepend a real-time notification pushed by the Socket.IO gateway.
  void ingestIncoming(Map<String, dynamic> payload) {
    final incoming = AppNotification(
      id: (payload['id'] as String?) ??
          'n_${DateTime.now().millisecondsSinceEpoch}',
      type: AppNotification.fromApi({
        'type': payload['type'] ?? 'system',
      }).type,
      user: User.fromApi(
        (payload['actor'] is Map<String, dynamic>)
            ? payload['actor'] as Map<String, dynamic>
            : {'id': payload['actor']},
      ),
      text: (payload['text'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((payload['createdAt'] as String?) ?? '') ??
              DateTime.now(),
      postPreview: payload['postPreview'] as String?,
      isRead: payload['isRead'] == true,
      isTrustEvent: payload['type'] == 'trust',
    );
    if (state.items.any((n) => n.id == incoming.id)) return;
    state = state.copyWith(items: [incoming, ...state.items]);
  }

  Future<void> markAllRead() async {
    final unreadIds = state.items.where((n) => !n.isRead).map((n) => n.id).toSet();
    state = state.copyWith(
      items: [
        for (final n in state.items)
          AppNotification(
            id: n.id,
            type: n.type,
            user: n.user,
            text: n.text,
            createdAt: n.createdAt,
            postPreview: n.postPreview,
            isRead: true,
            isTrustEvent: n.isTrustEvent,
          ),
      ],
    );
    try {
      await ref.watch(apiClientProvider).post('/notifications/read-all');
    } catch (_) {
      // Server never marked them read — restore the unread state so the UI
      // badge reflects reality.
      state = state.copyWith(
        items: [
          for (final n in state.items)
            if (unreadIds.contains(n.id))
              AppNotification(
                id: n.id,
                type: n.type,
                user: n.user,
                text: n.text,
                createdAt: n.createdAt,
                postPreview: n.postPreview,
                isRead: false,
                isTrustEvent: n.isTrustEvent,
              )
            else
              n,
        ],
      );
    }
  }

  Future<void> markRead(String id) async {
    state = state.copyWith(
      items: [
        for (final n in state.items)
          if (n.id == id)
            AppNotification(
              id: n.id,
              type: n.type,
              user: n.user,
              text: n.text,
              createdAt: n.createdAt,
              postPreview: n.postPreview,
              isRead: true,
              isTrustEvent: n.isTrustEvent,
            )
          else
            n,
      ],
    );
    try {
      await ref.watch(apiClientProvider).post('/notifications/$id/read');
    } catch (_) {
      // Revert to unread when the server call fails.
      state = state.copyWith(
        items: [
          for (final n in state.items)
            if (n.id == id)
              AppNotification(
                id: n.id,
                type: n.type,
                user: n.user,
                text: n.text,
                createdAt: n.createdAt,
                postPreview: n.postPreview,
                isRead: false,
                isTrustEvent: n.isTrustEvent,
              )
            else
              n,
        ],
      );
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
