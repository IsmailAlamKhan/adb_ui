import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../features.dart';

final packageInfoControllerProvider = StateNotifierProvider<PackageInfoController, PackageInfo?>(
  PackageInfoController.new,
);

class PackageInfoController extends StateNotifier<PackageInfo?> {
  final PackageInfoService packageInfoService;
  PackageInfoController(Ref ref)
      : packageInfoService = ref.read(packageInfoServiceProvider),
        super(null);

  Future<void> init() {
    return packageInfoService.getPackageInfo().then((value) => state = value);
  }
}
