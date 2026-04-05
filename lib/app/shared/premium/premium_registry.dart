import 'premium_feature_factory.dart';

class PremiumRegistry {
  static PremiumFeatureFactory? _factory;

  static void register(PremiumFeatureFactory factory) {
    _factory = factory;
  }

  static bool get isProPackageAvailable => _factory != null;

  static PremiumFeatureFactory? get factory => _factory;
}
