import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

const appName = 'ADB UI';

Color tintColor({
  required Color color,
  required Color tint,
  required double opacity,
}) {
  return Color.alphaBlend(tint.withOpacity(opacity), color);
}

Color surfaceTintColor({
  required BuildContext context,
  double opacity = .5,
}) {
  return tintColor(
    color: Theme.of(context).colorScheme.surface,
    tint: Theme.of(context).colorScheme.surfaceTint,
    opacity: opacity,
  );
}

typedef FutureCallback<T> = Future<T> Function();

bool isTabletOrLarger(BuildContext context) {
  return MediaQuery.of(context).size.width > 500;
}

bool isMobileSize(BuildContext context) {
  return MediaQuery.of(context).size.width < 500;
}

Future<Directory> getExternalDir() async {
  Directory directory;
  if (Platform.isAndroid) {
    directory = (await getExternalStorageDirectory())!;
  } else {
    directory = await getApplicationSupportDirectory();
  }
  return directory;
}

const bugReportUrl =
    'https://github.com/IsmailAlamKhan/adb_ui/issues/new?assignees=&labels=&template=bug_report.md&title=';

const appRepoUrl = 'https://github.com/IsmailAlamKhan/adb_ui';

const authorGitHubUrl = 'https://github.com/IsmailAlamKhan';
