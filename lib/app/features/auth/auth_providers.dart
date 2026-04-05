import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import 'auth_controller.dart';
import 'auth_model.dart';
import 'auth_service.dart';
import 'auth_service_noop.dart';
import 'auth_service_supabase.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  if (!SupabaseConfig.isConfigured) {
    return AuthServiceNoop();
  }
  final service = AuthServiceSupabase();
  ref.onDispose(service.dispose);
  return service;
});

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(ref.read(authServiceProvider)),
);

final currentUserProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authControllerProvider).maybeWhen(
        authenticated: (u) => u,
        orElse: () => null,
      );
});
