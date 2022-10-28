// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adb_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: avoid_private_typedef_functions, non_constant_identifier_names, subtype_of_sealed_class, invalid_use_of_internal_member, unused_element, constant_identifier_names, unnecessary_raw_strings, library_private_types_in_public_api

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

String $adbFilesHash() => r'c1269368458395b89840d4f648669d21f7c79fc0';

/// See also [adbFiles].
class AdbFilesProvider extends FutureProvider<List<AdbFileSystem>> {
  AdbFilesProvider({
    required this.device,
    this.path,
  }) : super(
          (ref) => adbFiles(
            ref,
            device: device,
            path: path,
          ),
          from: adbFilesProvider,
          name: r'adbFilesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : $adbFilesHash,
        );

  final AdbDevice device;
  final String? path;

  @override
  bool operator ==(Object other) {
    return other is AdbFilesProvider &&
        other.device == device &&
        other.path == path;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, device.hashCode);
    hash = _SystemHash.combine(hash, path.hashCode);

    return _SystemHash.finish(hash);
  }
}

typedef AdbFilesRef = FutureProviderRef<List<AdbFileSystem>>;

/// See also [adbFiles].
final adbFilesProvider = AdbFilesFamily();

class AdbFilesFamily extends Family<AsyncValue<List<AdbFileSystem>>> {
  AdbFilesFamily();

  AdbFilesProvider call({
    required AdbDevice device,
    String? path,
  }) {
    return AdbFilesProvider(
      device: device,
      path: path,
    );
  }

  @override
  FutureProvider<List<AdbFileSystem>> getProviderOverride(
    covariant AdbFilesProvider provider,
  ) {
    return call(
      device: provider.device,
      path: provider.path,
    );
  }

  @override
  List<ProviderOrFamily>? get allTransitiveDependencies => null;

  @override
  List<ProviderOrFamily>? get dependencies => null;

  @override
  String? get name => r'adbFilesProvider';
}

String $scrcpyAvailableHash() => r'9ed2aa5791e831a567493a4d615e8c355580edab';

/// See also [scrcpyAvailable].
final scrcpyAvailableProvider = FutureProvider<bool>(
  scrcpyAvailable,
  name: r'scrcpyAvailableProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : $scrcpyAvailableHash,
);
typedef ScrcpyAvailableRef = FutureProviderRef<bool>;
