import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> markAllRead() async {
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
    } catch (_) {/* ignore */}
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
    } catch (_) {/* ignore */}
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(NotificationsNotifier.new);
