import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((Ref ref) {
  return AuthService();
});

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AppUser?>>(
  (Ref ref) {
    return AuthController(ref.read(authServiceProvider));
  },
);

class AuthController extends StateNotifier<AsyncValue<AppUser?>> {
  AuthController(this._authService) : super(const AsyncValue.loading()) {
    _subscription = _authService.authStateChanges().listen(
      (AppUser? user) {
        state = AsyncValue.data(user);
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  final AuthService _authService;
  StreamSubscription<AppUser?>? _subscription;

  Future<void> signInWithGoogle() async {
    try {
      final AppUser user = await _authService.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> signInDemo() async {
    final AppUser user = await _authService.signInDemo();
    state = AsyncValue.data(user);
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
