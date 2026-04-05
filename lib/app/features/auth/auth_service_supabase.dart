import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../../utils/utils.dart';
import 'auth_model.dart';
import 'auth_service.dart';

class AuthServiceSupabase implements AuthService {
  AuthServiceSupabase() {
    _emitUser(_client.auth.currentUser);
    _authSub = _client.auth.onAuthStateChange.listen((data) {
      _emitUser(data.session?.user);
    });
  }

  sp.GoTrueClient get _auth => _client.auth;
  sp.SupabaseClient get _client => sp.Supabase.instance.client;

  StreamSubscription<dynamic>? _authSub;
  final _controller = StreamController<AuthUser?>.broadcast();

  void _emitUser(sp.User? user) {
    if (!_controller.isClosed) {
      _controller.add(_mapUser(user));
    }
  }

  AuthUser? _mapUser(sp.User? user) {
    if (user == null) return null;
    return AuthUser(id: user.id, email: user.email);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  bool get isAvailable => true;

  @override
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  @override
  Future<AuthUser?> signIn({required String email, required String password}) async {
    final response = await _auth.signInWithPassword(email: email, password: password);
    return _mapUser(response.user);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<AuthUser?> signUp({required String email, required String password}) async {
    final response = await _auth.signUp(email: email, password: password);
    if (response.user == null) {
      throw AppException(
        'Check your email to confirm sign-up before signing in.',
        'auth-email-confirm',
      );
    }
    return _mapUser(response.user);
  }

  void dispose() {
    _authSub?.cancel();
    _controller.close();
  }
}
