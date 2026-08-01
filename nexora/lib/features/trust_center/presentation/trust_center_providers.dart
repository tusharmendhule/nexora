import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/trust_repository.dart';

final trustRepositoryProvider = Provider<TrustRepository>((ref) {
  return TrustRepository(ref.watch(apiClientProvider));
});

class TrustCenterState {
  const TrustCenterState({
    this.overview = const TrustOverview(),
    this.isLoading = true,
  });

  final TrustOverview overview;
  final bool isLoading;

  TrustCenterState copyWith({TrustOverview? overview, bool? isLoading}) {
    return TrustCenterState(
      overview: overview ?? this.overview,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class TrustCenterNotifier extends Notifier<TrustCenterState> {
  @override
  TrustCenterState build() {
    Future<void>.microtask(_load);
    return const TrustCenterState();
  }

  Future<void> _load() async {
    try {
      final overview = await ref.watch(trustRepositoryProvider).fetchOverview();
      state = TrustCenterState(overview: overview, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refresh() => _load();
}

final trustCenterProvider =
    NotifierProvider<TrustCenterNotifier, TrustCenterState>(TrustCenterNotifier.new);
