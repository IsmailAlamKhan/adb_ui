import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:github/github.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'exception.dart';

const appName = 'Adb ui';

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

const featureRequestUrl =
    'https://github.com/IsmailAlamKhan/adb_ui/issues/new?assignees=&labels=&template=feature_request.md&title=';

const appRepoUrl = 'https://github.com/IsmailAlamKhan/adb_ui';

const changelogUrl = 'https://github.com/IsmailAlamKhan/adb_ui/CHANGELOG.md';
final githubRepoSlug = RepositorySlug.full('IsmailAlamKhan/adb_ui');

const riverpodKeepAlive = Riverpod(keepAlive: true);

String exceptionToString(Object exception) {
  late String message;

  if (exception is! Exception) {
    if (kDebugMode) {
      message = exception.toString();
    } else {
      message = 'Unknown error';
    }
  } else {
    if (exception is AppException) {
      message = exception.message;
    } else if (exception is PlatformException) {
      message = exception.message ?? exception.code;
    } else {
      message = exception.toString();
    }
  }
  return message;
}
