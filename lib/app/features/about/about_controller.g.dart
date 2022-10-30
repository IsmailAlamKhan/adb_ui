// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'about_controller.dart';

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

String $AboutControllerHash() => r'60367c3bdb7505b3ebe92f3ba05b773808a119d2';

/// See also [AboutController].
final aboutControllerProvider =
    AutoDisposeAsyncNotifierProvider<AboutController, AboutModel>(
  AboutController.new,
  name: r'aboutControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : $AboutControllerHash,
);
typedef AboutControllerRef = AutoDisposeAsyncNotifierProviderRef<AboutModel>;

abstract class _$AboutController extends AutoDisposeAsyncNotifier<AboutModel> {
  @override
  FutureOr<AboutModel> build();
}
