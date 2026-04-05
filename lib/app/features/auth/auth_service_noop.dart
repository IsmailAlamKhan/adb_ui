import 'dart:async';

import '../../utils/utils.dart';
import 'auth_model.dart';
import 'auth_service.dart';

class AuthServiceNoop implements AuthService {
  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  bool get isAvailable => false;

  @override
  Future<void> resetPassword(String email) async {
    throw AppException('Cloud account is not configured for this build.', 'auth-not-configured');
  }

  @override
  Future<AuthUser?> signIn({required String email, required String password}) async {
    throw AppException('Cloud account is not configured for this build.', 'auth-not-configured');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser?> signUp({required String email, required String password}) async {
    throw AppException('Cloud account is not configured for this build.', 'auth-not-configured');
  }
}
