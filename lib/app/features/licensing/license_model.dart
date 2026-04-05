sealed class LicenseState {
  const LicenseState();

  const factory LicenseState.free() = FreeLicenseState;

  factory LicenseState.trial({required DateTime expiresAt}) = TrialLicenseState;

  factory LicenseState.pro({
    required DateTime purchasedAt,
    List<String> deviceIds,
    int maxDevices,
  }) = ProLicenseState;
}

final class FreeLicenseState extends LicenseState {
  const FreeLicenseState();
}

final class TrialLicenseState extends LicenseState {
  TrialLicenseState({required this.expiresAt}) : super();

  final DateTime expiresAt;
}

final class ProLicenseState extends LicenseState {
  ProLicenseState({
    required this.purchasedAt,
    List<String>? deviceIds,
    this.maxDevices = 3,
  })  : deviceIds = deviceIds ?? const [],
        super();

  final DateTime purchasedAt;
  final List<String> deviceIds;
  final int maxDevices;
}

extension LicenseStateX on LicenseState {
  bool get isPro => this is ProLicenseState;

  bool get isTrialActive => switch (this) {
        TrialLicenseState(:final expiresAt) => DateTime.now().isBefore(expiresAt),
        _ => false,
      };

  bool get isTrialExpired => switch (this) {
        TrialLicenseState(:final expiresAt) => DateTime.now().isAfter(expiresAt),
        _ => false,
      };

  bool get hasPremiumAccess => isPro || isTrialActive;

  int get trialDaysRemaining => switch (this) {
        TrialLicenseState(:final expiresAt) => () {
            final remaining = expiresAt.difference(DateTime.now()).inDays;
            return remaining < 0 ? 0 : remaining;
          }(),
        _ => 0,
      };

  String get statusLabel => switch (this) {
        FreeLicenseState() => 'Free',
        TrialLicenseState() => () {
            final days = trialDaysRemaining;
            if (days == 0) return 'Trial expired';
            return 'Trial ($days days left)';
          }(),
        ProLicenseState() => 'Pro',
      };

  T when<T>({
    required T Function() free,
    required T Function(DateTime expiresAt) trial,
    required T Function(DateTime purchasedAt, List<String> deviceIds, int maxDevices) pro,
  }) {
    return switch (this) {
      FreeLicenseState() => free(),
      TrialLicenseState(:final expiresAt) => trial(expiresAt),
      ProLicenseState(:final purchasedAt, :final deviceIds, :final maxDevices) =>
        pro(purchasedAt, deviceIds, maxDevices),
    };
  }

  T maybeWhen<T>({
    T Function()? free,
    T Function(DateTime expiresAt)? trial,
    T Function(DateTime purchasedAt, List<String> deviceIds, int maxDevices)? pro,
    required T Function() orElse,
  }) {
    return switch (this) {
      FreeLicenseState() => free?.call() ?? orElse(),
      TrialLicenseState(:final expiresAt) => trial?.call(expiresAt) ?? orElse(),
      ProLicenseState(:final purchasedAt, :final deviceIds, :final maxDevices) =>
        pro?.call(purchasedAt, deviceIds, maxDevices) ?? orElse(),
    };
  }
}
