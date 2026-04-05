import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/premium/premium_feature.dart';
import '../../utils/utils.dart';
import '../auth/auth_model.dart';
import '../auth/auth_providers.dart';
import 'license_controller.dart';
import 'license_model.dart';
import 'license_service.dart';
import 'license_service_noop.dart';
import 'license_service_supabase.dart';
import 'machine_id.dart';

final licenseServiceProvider = Provider<LicenseService>((ref) {
  if (!SupabaseConfig.isConfigured) {
    return LicenseServiceNoop();
  }
  return LicenseServiceSupabase();
});

final stableMachineIdProvider = FutureProvider<String>((ref) => stableMachineId());

final licenseControllerProvider = StateNotifierProvider<LicenseController, LicenseState>((ref) {
  final service = ref.watch(licenseServiceProvider);
  final controller = LicenseController(ref, service);
  ref.listen<AuthState>(authControllerProvider, (_, next) {
    next.maybeWhen(
      authenticated: (_) => controller.refreshFromServer(),
      unauthenticated: () => controller.resetForSignOut(),
      orElse: () {},
    );
  });
  return controller;
});

final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(licenseControllerProvider).hasPremiumAccess;
});

final licenseStateProvider = Provider<LicenseState>((ref) {
  return ref.watch(licenseControllerProvider);
});

final isFeatureUnlockedProvider = Provider.family<bool, PremiumFeature>((ref, feature) {
  final license = ref.watch(licenseControllerProvider);
  final service = ref.watch(licenseServiceProvider);
  final machineAsync = ref.watch(stableMachineIdProvider);
  return machineAsync.maybeWhen(
    data: (id) => service.isFeatureUnlocked(feature, license, id),
    orElse: () => false,
  );
});
