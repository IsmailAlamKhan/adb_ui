import '../../shared/premium/premium_feature.dart';
import '../../utils/utils.dart';
import 'license_model.dart';
import 'license_service.dart';

class LicenseServiceNoop implements LicenseService {
  @override
  Future<String> createCheckoutSession({
    required String userId,
    required String email,
    required String deviceId,
  }) async {
    throw AppException('Licensing backend is not configured for this build.', 'license-not-configured');
  }

  @override
  Future<LicenseState> fetchLicense(String userId) async => const LicenseState.free();

  @override
  bool get isAvailable => false;

  @override
  bool isFeatureUnlocked(PremiumFeature feature, LicenseState state, String machineId) => false;

  @override
  Future<bool> canUseLicenseOnThisMachine(LicenseState state, String machineId) async =>
      state.hasPremiumAccess;

  @override
  Future<void> cacheLicenseLocally(LicenseState state, String? userId) async {}

  @override
  Future<({LicenseState state, DateTime? lastValidated})> loadCachedLicense() async {
    return (state: const LicenseState.free(), lastValidated: null);
  }

  @override
  Future<void> registerDevice(String userId, String deviceId) async {}

  @override
  Future<void> startTrial(String userId) async {
    throw AppException('Licensing backend is not configured for this build.', 'license-not-configured');
  }
}
