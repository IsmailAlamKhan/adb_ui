import 'auth_model.dart';

abstract class AuthService {
  AuthUser? get currentUser;

  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser?> signUp({required String email, required String password});

  Future<AuthUser?> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> resetPassword(String email);

  bool get isAvailable;
}
