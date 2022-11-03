import 'package:github/github.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';

enum UpdateAvailableState {
  updateAvailable,
  updateNotAvailable;
}

final packageInfoServiceProvider = Provider<PackageInfoService>(
  PackageInfoServiceImpl.new,
);

abstract class PackageInfoService {
  Future<PackageInfo> getPackageInfo();

  Future<UpdateAvailableState> newVersionAvailable();
}

class PackageInfoServiceImpl implements PackageInfoService {
  final GitHub github;
  PackageInfoServiceImpl(Ref ref) : github = ref.read(githubProvider);

  @override
  Future<PackageInfo> getPackageInfo() => PackageInfo.fromPlatform();
  int getExtendedVersionNumber(String version) {
    // Note that if you want to support bigger version cells than 99,
    // just increase the returned versionCells multipliers
    List versionCells = version.split('.');
    versionCells = versionCells.map((i) => int.parse(i)).toList();
    return versionCells[0] * 10000 + versionCells[1] * 100 + versionCells[2];
  }

  @override
  Future<UpdateAvailableState> newVersionAvailable() async {
    final packageInfo = await getPackageInfo();
    try {
      final currentVersion = packageInfo.version;
      final latestRelease = await github.repositories.getLatestRelease(githubRepoSlug);
      final latestVersion = latestRelease.tagName?.substring(1);
      if (latestVersion == null) return UpdateAvailableState.updateNotAvailable;
      final _currentVersion = getExtendedVersionNumber(currentVersion);
      final _latestVersion = getExtendedVersionNumber(latestVersion);

      return _currentVersion < _latestVersion
          ? UpdateAvailableState.updateAvailable
          : UpdateAvailableState.updateNotAvailable;
    } on GitHubError catch (e) {
      throw AppException(e.message, e.apiUrl);
    }
  }
}
