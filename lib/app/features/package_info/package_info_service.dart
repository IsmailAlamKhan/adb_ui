import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final packageInfoServiceProvider = Provider<PackageInfoService>(
  (ref) => PackageInfoServiceImpl(),
);

abstract class PackageInfoService {
  Future<PackageInfo> getPackageInfo();
}

class PackageInfoServiceImpl implements PackageInfoService {
  @override
  Future<PackageInfo> getPackageInfo() => PackageInfo.fromPlatform();
}
