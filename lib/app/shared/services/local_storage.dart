import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocalStorageKeys {
  commands('commands'),
  settings('settings');

  final String key;
  const LocalStorageKeys(this.key);
}

mixin LocalStorageModel {
  Map<String, dynamic> toJson();
}

final localStorageProvider = Provider<LocalStorage>((ref) => LocalStorageSharedPrefImpl());

abstract class LocalStorage {
  Future<void> init();
  Future<void> clear();
  Future<void> delete(LocalStorageKeys key);
  Future<bool> containsKey(LocalStorageKeys key);
  Future<T> get<T>(
    LocalStorageKeys key, {
    T? defaultValue,
    T Function(dynamic)? fromJson,
  });
  Future<void> set<T>(LocalStorageKeys key, T value);
}

class LocalStorageSharedPrefImpl implements LocalStorage {
  SharedPreferences? _sharedPreferences;
  SharedPreferences get sharedPreferences {
    assert(_sharedPreferences != null, 'LocalStorage not initialized');

    return _sharedPreferences!;
  }

  @override
  Future<void> clear() => sharedPreferences.clear();

  @override
  Future<bool> containsKey(LocalStorageKeys key) async => sharedPreferences.containsKey(key.key);

  @override
  Future<void> delete(LocalStorageKeys key) => sharedPreferences.remove(key.key);

  @override
  Future<T> get<T>(
    LocalStorageKeys key, {
    T? defaultValue,
    T Function(dynamic)? fromJson,
  }) async {
    final value = sharedPreferences.get(key.key);
    if (value == null && defaultValue != null) {
      return defaultValue;
    }
    if (fromJson != null && value != null) {
      return fromJson(jsonDecode(value as String));
    }
    return value as T;
  }

  @override
  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  @override
  Future<void> set<T>(LocalStorageKeys key, T value) {
    if (value is bool) {
      return sharedPreferences.setBool(key.key, value);
    } else if (value is double) {
      return sharedPreferences.setDouble(key.key, value);
    } else if (value is int) {
      return sharedPreferences.setInt(key.key, value);
    } else if (value is String) {
      return sharedPreferences.setString(key.key, value);
    } else if (value is Map || value is List || value is LocalStorageModel) {
      return sharedPreferences.setString(key.key, jsonEncode(value));
      // return sharedPreferences.setString(key.key, jsonEncode(value));
    }
    throw Exception('Unsupported type');
  }
}
