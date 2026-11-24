import 'package:adb_ui/app/features/about/bug_report.dart';
import 'package:flutter_test/flutter_test.dart';

const info = BugReportInfo(
  version: '0.0.19',
  os: 'macOS Version 26.1',
  style: 'Workbench',
  adbVersion: 'Android Debug Bridge version 1.0.41 · Version 37.0.0',
  phone: 'Pixel 10 Pro, Android 17, Wi-Fi',
);

void main() {
  group('logExcerpt', () {
    test('keeps message and error lines, hides home and PATH', () {
      final out = logExcerpt([
        'Messege: App Started',
        'StackTrace=#0 main (file:///x.dart)',
        'Messege: Loaded 26 environment variables. PATH=/Users/me/bin:/usr/bin',
        'Messege: Created temp sh file at /Users/me/Library/Application Support/com.adb-ui/env.sh',
        'Error: something failed in /Users/me/project',
        '#1 frame',
      ], home: '/Users/me');
      expect(out, [
        'Messege: App Started',
        'Messege: Created temp sh file at ~/Library/Application Support/com.adb-ui/env.sh',
        'Error: something failed in ~/project',
      ]);
    });

    test('cuts long lines', () {
      final out = logExcerpt(['Messege: ${'x' * 1000}']);
      expect(out.single.length, lessThanOrEqualTo(301));
    });
  });

  group('bugIssueUrl', () {
    test('pre-fills label, setup, zip name and log lines', () {
      final uri = Uri.parse(bugIssueUrl(info, 'adb-ui-logs-2026-11-24-1900.zip', ['Messege: boom']));
      expect(uri.path, '/IsmailAlamKhan/adb_ui/issues/new');
      expect(uri.queryParameters['labels'], 'bug');
      final body = uri.queryParameters['body']!;
      expect(body, contains('adb-ui-logs-2026-11-24-1900.zip'));
      expect(body, contains('- ADB UI version: 0.0.19'));
      expect(body, contains('- Phone: Pixel 10 Pro, Android 17, Wi-Fi'));
      expect(body, contains('Messege: boom'));
    });

    test('stays under the URL limit by dropping the oldest lines', () {
      final lines = [for (var i = 0; i < 200; i++) 'Messege: line $i ${'y' * 250}'];
      final url = bugIssueUrl(info, 'logs.zip', lines);
      expect(url.length, lessThanOrEqualTo(maxIssueUrlLength));
      final body = Uri.parse(url).queryParameters['body']!;
      expect(body, contains('line 199'));
      expect(body, isNot(contains('line 0 ')));
    });

    test('no log lines: no details block', () {
      final body = Uri.parse(bugIssueUrl(info, 'logs.zip', const [])).queryParameters['body']!;
      expect(body, isNot(contains('<details>')));
    });
  });

  test('featureIssueUrl has version and OS', () {
    final uri = Uri.parse(featureIssueUrl(version: '0.0.19', os: 'Windows 11'));
    expect(uri.queryParameters['labels'], 'enhancement');
    expect(uri.queryParameters['body'], contains('_ADB UI 0.0.19 on Windows 11_'));
  });
}
