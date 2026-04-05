import '../../shared/premium/premium_feature.dart';
import 'license_model.dart';

abstract class LicenseService {
  bool get isAvailable;

  Future<LicenseState> fetchLicense(String userId);

  Future<void> cacheLicenseLocally(LicenseState state, String? userId);

  Future<({LicenseState state, DateTime? lastValidated})> loadCachedLicense();

  Future<String> createCheckoutSession({
    required String userId,
    required String email,
    required String deviceId,
  });

  Future<void> startTrial(String userId);

  Future<void> registerDevice(String userId, String deviceId);

  bool isFeatureUnlocked(PremiumFeature feature, LicenseState state, String machineId);

  /// When [state] is pro, returns false if this machine is not registered and slots are full.
  Future<bool> canUseLicenseOnThisMachine(LicenseState state, String machineId);
}
