import 'dart:io';

import 'package:github/github.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

final aboutServiceProvider = Provider<AboutService>(GithubAboutServiceImpl.new);

abstract class AboutService {
  Future<AboutModel> checkUpdateAvailable();

  Future<void> downloadUpdates();
}

class GithubAboutServiceImpl extends AboutService {
  final GitHub github;
  final PackageInfoService packageInfoService;
  GithubAboutServiceImpl(Ref ref)
      : github = ref.read(githubProvider),
        packageInfoService = ref.watch(packageInfoServiceProvider);

  @override
  Future<AboutModel> checkUpdateAvailable() => packageInfoService
      .newVersionAvailable()
      .then((value) => AboutModel(updateAvailable: value == UpdateAvailableState.updateAvailable));

  @override
  Future<void> downloadUpdates() async {
    try {
      final latestRelease = await github.repositories.getLatestRelease(githubRepoSlug);
      final os = Platform.operatingSystem;
      final installUrl = latestRelease.assets!
          .firstWhere((element) => element.name!.contains('setup-$os'))
          .browserDownloadUrl;
      if (installUrl == null) return;
      await launchUrlString(installUrl);
    } on GitHubError catch (e) {
      throw AppException(e.message, e.apiUrl);
    }
  }
}
