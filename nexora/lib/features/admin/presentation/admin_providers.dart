import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/admin_models.dart';

class AdminSettings {
  const AdminSettings({
    this.maintenanceMode = false,
    this.verifiedOnlyExplore = false,
    this.aiTriage = true,
  });

  final bool maintenanceMode;
  final bool verifiedOnlyExplore;
  final bool aiTriage;

  factory AdminSettings.fromApi(Map<String, dynamic> json) {
    return AdminSettings(
      maintenanceMode: json['maintenanceMode'] == true,
      verifiedOnlyExplore: json['verifiedOnlyExplore'] == true,
      aiTriage: json['aiTriage'] != false,
    );
  }

  AdminSettings copyWith({
    bool? maintenanceMode,
    bool? verifiedOnlyExplore,
    bool? aiTriage,
  }) {
    return AdminSettings(
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      verifiedOnlyExplore: verifiedOnlyExplore ?? this.verifiedOnlyExplore,
      aiTriage: aiTriage ?? this.aiTriage,
    );
  }
}

class AdminState {
  const AdminState({
    this.stats = const AdminStats(),
    this.settings = const AdminSettings(),
    this.isLoading = true,
    this.saving = false,
    this.error,
  });

  final AdminStats stats;
  final AdminSettings settings;
  final bool isLoading;
  final bool saving;
  final String? error;

  AdminState copyWith({
    AdminStats? stats,
    AdminSettings? settings,
    bool? isLoading,
    bool? saving,
    String? error,
    bool clearError = false,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      saving: saving ?? this.saving,
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
      final api = ref.watch(apiClientProvider);
      final results = await Future.wait<dynamic>([
        api.get('/admin/stats'),
        api.get('/admin/settings'),
      ]);
      final statsJson = (results[0] as Map<String, dynamic>?) ?? const {};
      final settingsJson =
          (results[1] as Map<String, dynamic>?)?['settings'] ??
              const <String, dynamic>{};
      state = AdminState(
        stats: AdminStats.fromApi(statsJson),
        settings: AdminSettings.fromApi(
          settingsJson as Map<String, dynamic>,
        ),
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

  /// Persists the given switch values via PUT /admin/settings. On failure the
  /// previous values are restored so the UI never lies about server state.
  Future<void> saveSettings(AdminSettings next) async {
    state = state.copyWith(saving: true);
    final previous = state.settings;
    state = state.copyWith(settings: next);
    try {
      await ref.watch(apiClientProvider).put('/admin/settings', body: {
        'maintenanceMode': next.maintenanceMode,
        'verifiedOnlyExplore': next.verifiedOnlyExplore,
        'aiTriage': next.aiTriage,
      });
    } catch (_) {
      state = state.copyWith(settings: previous);
    } finally {
      state = state.copyWith(saving: false);
    }
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(AdminNotifier.new);
