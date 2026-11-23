import 'dart:convert';

import 'package:adb_ui/app/features/ai/ai_filter_mapper.dart';
import 'package:adb_ui/app/features/apps/apps_model.dart';
import 'package:adb_ui/app/features/file_preview/file_preview_model.dart';
import 'package:adb_ui/app/features/logcat/logcat_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('app info (spec/features/app-icons.md)', () {
    test('parses pm version codes', () {
      final v = parsePackageVersions(
        'package:com.Slack versionCode:90016409\npackage:com.pathao.user versionCode:549\nnoise\n',
      );
      expect(v, {'com.Slack': 90016409, 'com.pathao.user': 549});
    });

    test('parses helper info lines', () {
      final png = base64Encode([137, 80, 78, 71]);
      final a = parseHelperInfoLine('com.Slack\tSlack\t$png')!;
      expect(a.package, 'com.Slack');
      expect(a.label, 'Slack');
      expect(a.icon, [137, 80, 78, 71]);
      final b = parseHelperInfoLine('com.example\t\t-')!;
      expect(b.label, isNull);
      expect(b.icon, isNull);
      expect(b.name, 'com.example');
      expect(parseHelperInfoLine('Exception in thread main'), isNull);
      expect(parseHelperInfoLine(''), isNull);
    });

    test('letter tiles', () {
      expect(appLetter('com.google.android.gm', 'Gmail'), 'G');
      expect(appLetter('com.spotify.music', null), 'M');
      expect(appLetter('com.example.app', ''), 'E');
      expect(appHue('com.Slack'), appHue('com.Slack'));
      expect(appHue('com.Slack'), inInclusiveRange(0, 359));
    });

    test('AI filter resolves an app by its label', () {
      const packages = ['com.google.android.gm', 'com.Slack'];
      const labels = {'com.google.android.gm': 'Gmail', 'com.Slack': 'Slack'};
      final rules = AiFilterMapper.fromRules('errors from gmail', packages: packages, labels: labels);
      expect(rules['package'], 'com.google.android.gm');
      expect(rules['preset'], 'errors');
      expect(rules.containsKey('text'), isFalse, reason: 'the app name is not a search word');
      final filter = AiFilterMapper.toFilter(
        {'package': 'com.google.android.gm', 'explanation': 'Gmail errors'},
        packages: packages,
        labels: labels,
        request: 'errors from gmail',
      );
      expect(filter.package, 'com.google.android.gm');
      expect(filter.preset, LogPreset.errors);
    });
  });

  group('file preview (spec/features/file-preview.md)', () {
    test('kind by extension', () {
      expect(FilePreviewKind.of('/sdcard/DCIM/IMG_1.JPG'), FilePreviewKind.image);
      expect(FilePreviewKind.of('/sdcard/a.mp4'), FilePreviewKind.video);
      expect(FilePreviewKind.of('/sdcard/song.flac'), FilePreviewKind.audio);
      expect(FilePreviewKind.of('/data/local/tmp/app.log'), FilePreviewKind.text);
      expect(FilePreviewKind.of('/sdcard/x.heic'), FilePreviewKind.other);
      expect(FilePreviewKind.of('/sdcard/.nomedia'), FilePreviewKind.other);
      expect(FilePreviewKind.of('/sdcard/README'), FilePreviewKind.other);
    });

    test('stat output', () {
      final info = RemoteFileInfo.parse('/sdcard/a.txt', '1234|1700000000\n')!;
      expect(info.size, 1234);
      expect(info.modified, DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000));
      expect(info.name, 'a.txt');
      expect(RemoteFileInfo.parse('/x', "stat: '/x': No such file or directory"), isNull);
    });

    test('sizes and quoting', () {
      expect(formatFileSize(1), '1 byte');
      expect(formatFileSize(999), '999 bytes');
      expect(formatFileSize(1500), '1.5 KB');
      expect(formatFileSize(340000), '340 KB');
      expect(formatFileSize(2400000), '2.4 MB');
      expect(shellQuote("/sdcard/it's here.txt"), r"'/sdcard/it'\''s here.txt'");
      expect(prettyJsonOrSame('{"a":1}', const JsonEncoder.withIndent('  ').convert, jsonDecode), '{\n  "a": 1\n}');
      expect(prettyJsonOrSame('not json', const JsonEncoder.withIndent('  ').convert, jsonDecode), 'not json');
    });
  });
}
