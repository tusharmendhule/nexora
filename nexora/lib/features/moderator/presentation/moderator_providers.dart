import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/moderation_models.dart';

class ModeratorStats {
  const ModeratorStats({
    this.pending = 0,
    this.resolvedToday = 0,
    this.avgResponseHours = 0,
    this.trustActions = 0,
  });

  final int pending;
  final int resolvedToday;
  final int avgResponseHours;
  final int trustActions;
}

class ModeratorState {
  const ModeratorState({
    this.queue = const [],
    this.stats = const ModeratorStats(),
    this.isLoading = true,
  });

  final List<ModerationItem> queue;
  final ModeratorStats stats;
  final bool isLoading;

  ModeratorState copyWith({
    List<ModerationItem>? queue,
    ModeratorStats? stats,
    bool? isLoading,
  }) {
    return ModeratorState(
      queue: queue ?? this.queue,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ModeratorNotifier extends Notifier<ModeratorState> {
  @override
  ModeratorState build() {
    Future<void>.microtask(_load);
    return const ModeratorState();
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    try {
      final results = await Future.wait<dynamic>([
        api.get('/moderation/queue'),
        api.get('/moderation/stats'),
      ]);
      final queueData = (results[0] as Map<String, dynamic>?)?['data'] as List? ?? const [];
      final statsData = (results[1] as Map<String, dynamic>?)?['stats'] as Map<String, dynamic>? ?? const {};
      state = ModeratorState(
        queue: queueData
            .map((i) => ModerationItem.fromApi(i as Map<String, dynamic>))
            .toList(),
        stats: ModeratorStats(
          pending: ((statsData['pending'] as num?) ?? 0).toInt(),
          resolvedToday: ((statsData['resolvedToday'] as num?) ?? 0).toInt(),
          avgResponseHours: ((statsData['avgResponseHours'] as num?) ?? 0).toInt(),
          trustActions: ((statsData['trustActions'] as num?) ?? 0).toInt(),
        ),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> resolve(String itemId) async {
    final item = state.queue.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;
    state = state.copyWith(
      queue: state.queue.where((i) => i.id != itemId).toList(),
    );
    try {
      await ref.read(apiClientProvider).post('/moderation/action', body: {
        'action': 'dismiss',
        'targetType': item.targetType,
        'targetId': item.targetId,
        'reportId': item.reportId,
        'reason': item.reason,
      });
    } catch (_) {/* ignore */}
  }

  Future<void> takeAction(String itemId, String action) async {
    final item = state.queue.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;
    state = state.copyWith(
      queue: state.queue.where((i) => i.id != itemId).toList(),
    );
    try {
      await ref.read(apiClientProvider).post('/moderation/action', body: {
        'action': action,
        'targetType': item.targetType,
        'targetId': item.targetId,
        'reportId': item.reportId,
        'reason': item.reason,
      });
    } catch (_) {/* ignore */}
  }

  Future<void> resolveAll() async {
    final items = state.queue;
    state = state.copyWith(queue: const []);
    for (final item in items) {
      try {
        await ref.read(apiClientProvider).post('/moderation/action', body: {
          'action': 'dismiss',
          'targetType': item.targetType,
          'targetId': item.targetId,
          'reportId': item.reportId,
          'reason': item.reason,
        });
      } catch (_) {/* keep clearing locally */}
    }
  }
}

final moderatorProvider =
    NotifierProvider<ModeratorNotifier, ModeratorState>(ModeratorNotifier.new);
