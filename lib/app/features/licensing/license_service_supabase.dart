import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;

import '../../shared/premium/premium_feature.dart';
import '../../utils/utils.dart';
import 'license_model.dart';
import 'license_service.dart';

const _cacheKey = 'adb_ui_license_cache_v1';

class LicenseServiceSupabase implements LicenseService {
  sp.SupabaseClient get _client => sp.Supabase.instance.client;

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  @override
  bool get isAvailable => true;

  @override
  Future<LicenseState> fetchLicense(String userId) async {
    final row = await _client.from('licenses').select().eq('user_id', userId).maybeSingle();
    if (row == null) return const LicenseState.free();
    return _licenseFromRow(Map<String, dynamic>.from(row));
  }

  LicenseState _licenseFromRow(Map<String, dynamic> row) {
    final status = row['status'] as String? ?? 'active';
    if (status != 'active') return const LicenseState.free();

    final plan = row['plan'] as String? ?? 'free';
    switch (plan) {
      case 'pro':
        final purchasedRaw = row['purchased_at'];
        final purchasedAt = purchasedRaw != null
            ? DateTime.parse(purchasedRaw as String)
            : DateTime.fromMillisecondsSinceEpoch(0);
        final devices = (row['device_ids'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[];
        final maxDevices = (row['max_devices'] as num?)?.toInt() ?? 3;
        return LicenseState.pro(
          purchasedAt: purchasedAt,
          deviceIds: devices,
          maxDevices: maxDevices,
        );
      case 'trial':
        final ends = row['trial_ends_at'];
        if (ends == null) return const LicenseState.free();
        return LicenseState.trial(expiresAt: DateTime.parse(ends as String));
      default:
        return const LicenseState.free();
    }
  }

  @override
  Future<void> cacheLicenseLocally(LicenseState state, String? userId) async {
    final prefs = await _prefs();
    final map = <String, dynamic>{
      'userId': userId,
      'lastValidated': DateTime.now().toIso8601String(),
      ..._stateToJson(state),
    };
    await prefs.setString(_cacheKey, jsonEncode(map));
  }

  Map<String, dynamic> _stateToJson(LicenseState state) {
    return state.when(
      free: () => {'kind': 'free'},
      trial: (expiresAt) => {
        'kind': 'trial',
        'expiresAt': expiresAt.toIso8601String(),
      },
      pro: (purchasedAt, deviceIds, maxDevices) => {
        'kind': 'pro',
        'purchasedAt': purchasedAt.toIso8601String(),
        'deviceIds': deviceIds,
        'maxDevices': maxDevices,
      },
    );
  }

  LicenseState _stateFromJson(Map<String, dynamic> map) {
    final kind = map['kind'] as String? ?? 'free';
    switch (kind) {
      case 'trial':
        final ends = map['expiresAt'] as String?;
        if (ends == null) return const LicenseState.free();
        return LicenseState.trial(expiresAt: DateTime.parse(ends));
      case 'pro':
        final p = map['purchasedAt'] as String?;
        if (p == null) return const LicenseState.free();
        final devices = (map['deviceIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            <String>[];
        final max = (map['maxDevices'] as num?)?.toInt() ?? 3;
        return LicenseState.pro(
          purchasedAt: DateTime.parse(p),
          deviceIds: devices,
          maxDevices: max,
        );
      default:
        return const LicenseState.free();
    }
  }

  @override
  Future<({LicenseState state, DateTime? lastValidated})> loadCachedLicense() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return (state: const LicenseState.free(), lastValidated: null);
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final last = map['lastValidated'] as String?;
      return (
        state: _stateFromJson(map),
        lastValidated: last != null ? DateTime.tryParse(last) : null,
      );
    } catch (_) {
      return (state: const LicenseState.free(), lastValidated: null);
    }
  }

  @override
  Future<String> createCheckoutSession({
    required String userId,
    required String email,
    required String deviceId,
  }) async {
    final res = await _client.functions.invoke(
      'create-checkout',
      body: {
        'user_id': userId,
        'email': email,
        'device_id': deviceId,
      },
    );
    if (res.status != 200) {
      throw AppException(
        res.data?.toString() ?? 'Checkout failed (${res.status})',
        'checkout-failed',
      );
    }
    final data = res.data;
    if (data is Map && data['url'] is String) {
      return data['url'] as String;
    }
    if (data is Map && data['data'] is Map && (data['data'] as Map)['url'] is String) {
      return (data['data'] as Map)['url'] as String;
    }
    throw AppException('Checkout response missing url', 'checkout-bad-response');
  }

  @override
  Future<void> startTrial(String userId) async {
    final ends = DateTime.now().add(const Duration(days: 14));
    await _client.from('licenses').update({
      'plan': 'trial',
      'trial_ends_at': ends.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  @override
  Future<void> registerDevice(String userId, String deviceId) async {
    final row = await _client
        .from('licenses')
        .select('device_ids,max_devices')
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return;
    final ids = (row['device_ids'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
    if (ids.contains(deviceId)) return;
    final max = (row['max_devices'] as num?)?.toInt() ?? 3;
    if (ids.length >= max) {
      throw AppException(
        'This license is active on the maximum number of devices. Remove one from your account to continue.',
        'license-max-devices',
      );
    }
    ids.add(deviceId);
    await _client.from('licenses').update({
      'device_ids': ids,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('user_id', userId);
  }

  @override
  bool isFeatureUnlocked(PremiumFeature feature, LicenseState state, String machineId) {
    if (!state.hasPremiumAccess) return false;
    return state.maybeWhen(
      pro: (_, ids, max) => ids.contains(machineId) || ids.length < max,
      orElse: () => true,
    );
  }

  @override
  Future<bool> canUseLicenseOnThisMachine(LicenseState state, String machineId) async {
    if (!state.isPro) return state.hasPremiumAccess;
    return state.maybeWhen(
      pro: (_, ids, max) => ids.contains(machineId) || ids.length < max,
      orElse: () => false,
    );
  }
}
