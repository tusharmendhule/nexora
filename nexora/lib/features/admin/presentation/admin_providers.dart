import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/admin_models.dart';

class AdminState {
  const AdminState({this.stats = const AdminStats(), this.isLoading = true, this.error});

  final AdminStats stats;
  final bool isLoading;
  final String? error;

  AdminState copyWith({AdminStats? stats, bool? isLoading, String? error, bool clearError = false}) {
    return AdminState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() {
    Future<void>.microtask(_load);
    return const AdminState();
  }

  Future<void> _load() async {
    try {
      final json = await ref.watch(apiClientProvider).get('/admin/stats');
      state = AdminState(
        stats: AdminStats.fromApi((json as Map<String, dynamic>?) ?? const {}),
        isLoading: false,
      );
    } catch (e) {
      state = const AdminState(
        isLoading: false,
        error: 'Admin access required or service unavailable.',
      );
    }
  }

  Future<void> refresh() => _load();
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);
