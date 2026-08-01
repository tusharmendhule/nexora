import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import '../data/auth_repository.dart';

/// Always the real API-backed repository (email/password, MongoDB users).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

/// Auth UI state.
class AuthState {
  const AuthState({
    this.user,
    this.isOnboarded = false,
    this.isAgeVerified = false,
    this.isLoading = false,
    this.error,
  });

  final User? user;
  final bool isOnboarded;
  final bool isAgeVerified;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isOnboarded,
    bool? isAgeVerified,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository = ref.watch(authRepositoryProvider);
  Future<void>? _restoreFuture;

  @override
  AuthState build() {
    // When the access token can no longer be renewed, drop the session.
    ref.read(apiClientProvider).onSessionExpired = () {
      state = state.copyWith(user: null, isLoading: false);
    };
    // Restore a persisted session (token + user) so users stay signed in.
    _restoreFuture ??= _restoreSession();
    return const AuthState();
  }

  /// Completes once the persisted-session restore has settled. The splash
  /// screen awaits this before routing so it never flashes the login screen
  /// to an already-authenticated user.
  Future<void> ensureRestored() => _restoreFuture ?? Future.value();

  Future<void> _restoreSession() async {
    try {
      final user = await _repository.restoreSession();
      if (user != null) {
        ref.read(socketServiceProvider).connect();
        state = state.copyWith(
          user: user,
          isOnboarded: true,
          isAgeVerified: true,
        );
      }
    } catch (e) {
      debugPrint('session restore failed: $e');
    }
  }

  void completeOnboarding() => state = state.copyWith(isOnboarded: true);

  void completeAgeVerification() => state = state.copyWith(isAgeVerified: true);

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signInWithEmail(email, password);
      ref.read(socketServiceProvider).connect();
      state = state.copyWith(
        user: user,
        isOnboarded: true,
        isAgeVerified: true,
        isLoading: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      debugPrint('signIn error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signUp(
        name: name,
        username: username,
        email: email,
        password: password,
      );
      ref.read(socketServiceProvider).connect();
      state = state.copyWith(
        user: user,
        isOnboarded: true,
        isAgeVerified: true,
        isLoading: false,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (e) {
      debugPrint('signUp error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  /// Guest login — creates an anonymous MongoDB user.
  Future<bool> signInAsGuest() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repository.signInAsGuest();
      ref.read(socketServiceProvider).connect();
      state = state.copyWith(
        user: user,
        isOnboarded: true,
        isAgeVerified: true,
        isLoading: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      debugPrint('guest sign-in error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Guest sign-in failed. Please try again.',
      );
      return false;
    }
  }

  /// Uploads a new avatar to Cloudinary and refreshes the signed-in user.
  Future<bool> uploadAvatar(List<int> bytes, {String filename = 'avatar.jpg'}) async {
    try {
      final user = await _repository.uploadAvatar(bytes, filename: filename);
      state = state.copyWith(user: user);
      return true;
    } catch (e) {
      debugPrint('uploadAvatar error: $e');
      state = state.copyWith(error: 'Avatar upload failed. Please try again.');
      return false;
    }
  }

  /// Persists profile edits to the API and the signed-in user state.
  Future<bool> updateProfile({
    String? name,
    String? username,
    String? bio,
    String? location,
    String? link,
    String? avatarUrl,
  }) async {
    final current = state.user;
    if (current == null) return false;
    try {
      final updated = await _repository.updateProfile(
        name: name,
        username: username,
        bio: bio,
        location: location,
        link: link,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(user: updated);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    ref.read(socketServiceProvider).disconnect();
    await _repository.signOut();
    state = state.copyWith(user: null, isLoading: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
