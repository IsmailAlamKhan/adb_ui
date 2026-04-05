import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/utils.dart';
import '../auth/auth_providers.dart';
import 'license_model.dart';
import 'license_service.dart';
import 'machine_id.dart';

class LicenseController extends StateNotifier<LicenseState> {
  LicenseController(this._ref, this._service) : super(const LicenseState.free());

  final Ref _ref;
  final LicenseService _service;

  Future<void> hydrate() async {
    final cached = await _service.loadCachedLicense();
    state = cached.state;
    await refreshFromServer();
  }

  Future<void> refreshFromServer() async {
    final user = _ref.read(currentUserProvider);
    if (user == null || !_service.isAvailable) {
      if (user == null) state = const LicenseState.free();
      return;
    }

    final cached = await _service.loadCachedLicense();
    try {
      final remote = await _service.fetchLicense(user.id);
      await _service.cacheLicenseLocally(remote, user.id);
      state = remote;
      await _tryRegisterDevice(remote);
    } catch (e, st) {
      LogFile.instance.dispath('refreshFromServer license', error: e, stackTrace: st);
      final last = cached.lastValidated;
      if (last != null &&
          DateTime.now().difference(last) <= const Duration(days: 7) &&
          cached.state != const LicenseState.free()) {
        state = cached.state;
      } else {
        state = const LicenseState.free();
      }
    }
  }

  Future<void> _tryRegisterDevice(LicenseState remote) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final machineId = await stableMachineId();
    await remote.maybeWhen(
      pro: (_, deviceIds, maxDevices) async {
        if (deviceIds.contains(machineId)) return;
        if (deviceIds.length >= maxDevices) return;
        try {
          await _service.registerDevice(user.id, machineId);
          final updated = await _service.fetchLicense(user.id);
          await _service.cacheLicenseLocally(updated, user.id);
          state = updated;
        } catch (e, st) {
          LogFile.instance.dispath('registerDevice', error: e, stackTrace: st);
        }
      },
      orElse: () async {},
    );
  }

  void resetForSignOut() {
    state = const LicenseState.free();
    Future.microtask(() => _service.cacheLicenseLocally(const LicenseState.free(), null));
  }

  Future<void> startTrial() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      throw AppException('Sign in to start a trial.', 'license-needs-auth');
    }
    await _service.startTrial(user.id);
    await refreshFromServer();
  }

  Future<void> purchasePro() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      throw AppException('Sign in to upgrade.', 'license-needs-auth');
    }
    final email = user.email ?? '';
    final machineId = await stableMachineId();
    final url = await _service.createCheckoutSession(
      userId: user.id,
      email: email,
      deviceId: machineId,
    );
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw AppException('Could not open checkout in the browser.', 'checkout-launch-failed');
    }
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      await refreshFromServer();
      if (state.isPro) return;
    }
  }
}
