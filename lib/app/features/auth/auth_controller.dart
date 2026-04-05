import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import 'auth_model.dart';
import 'auth_service.dart';

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._service) : super(const AuthState.loading()) {
    _userSubscription = _service.authStateChanges.listen(_onRemoteUser);
    _syncFromService();
  }

  final AuthService _service;
  StreamSubscription<AuthUser?>? _userSubscription;

  void _syncFromService() {
    final user = _service.currentUser;
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  void _onRemoteUser(AuthUser? user) {
    if (user != null) {
      state = AuthState.authenticated(user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _service.signIn(email: email, password: password);
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e, st) {
      LogFile.instance.dispath('signIn failed', error: e, stackTrace: st);
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _service.signUp(email: email, password: password);
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = const AuthState.unauthenticated();
      }
    } catch (e, st) {
      LogFile.instance.dispath('signUp failed', error: e, stackTrace: st);
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    try {
      await _service.signOut();
      state = const AuthState.unauthenticated();
    } catch (e, st) {
      LogFile.instance.dispath('signOut failed', error: e, stackTrace: st);
      state = AuthState.error(e.toString());
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _service.resetPassword(email);
    } catch (e, st) {
      LogFile.instance.dispath('resetPassword failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  void clearError() {
    state.maybeWhen(
      error: (_) => _syncFromService(),
      orElse: () {},
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
