import 'package:adb_ui/app/features/update_checker/update_model.dart';
import 'package:flutter_test/flutter_test.dart';

AppRelease release(String tag, {List<String> assets = const [], bool draft = false, bool pre = false}) =>
    AppRelease(
      version: AppVersion.tryParse(tag)!,
      tag: tag,
      notes: '## ${tag.substring(1)}\n\n- change in $tag\n',
      draft: draft,
      prerelease: pre,
      assets: [for (final a in assets) InstallerAsset(name: a, url: 'https://x/$a', size: 10)],
    );

const all = ['adb-ui-setup-macos.dmg', 'adb-ui-setup-windows.exe', 'adb-ui-setup-linux.zip'];

void main() {
  group('AppVersion', () {
    test('parses tags with v, suffixes and build numbers', () {
      expect(AppVersion.tryParse('v0.0.18').toString(), '0.0.18');
      expect(AppVersion.tryParse('0.0.19-beta').toString(), '0.0.19');
      expect(AppVersion.tryParse('1.2.3+4').toString(), '1.2.3');
      expect(AppVersion.tryParse('latest'), isNull);
      expect(AppVersion.tryParse(''), isNull);
      expect(AppVersion.tryParse(null), isNull);
    });

    test('compares number by number, beyond 99', () {
      final v = AppVersion.tryParse;
      expect(v('0.0.100')! > v('0.0.99')!, isTrue);
      expect(v('1.0.0')! > v('0.99.99')!, isTrue);
      expect(v('0.0.18')! < v('0.0.19')!, isTrue);
      expect(v('1.2')!, v('1.2.0')!);
      expect(v('1.2').hashCode, v('1.2.0').hashCode);
    });
  });

  group('pickUpdate', () {
    final current = AppVersion.tryParse('0.0.18')!;

    test('newest newer release with this OS installer', () {
      final releases = [release('v0.0.20', assets: all), release('v0.0.19', assets: all), release('v0.0.18', assets: all)];
      expect(pickUpdate(releases, current, 'macos')!.tag, 'v0.0.20');
    });

    test('skips a release whose installer is not uploaded yet', () {
      final releases = [
        release('v0.0.20', assets: ['adb-ui-setup-windows.exe']),
        release('v0.0.19', assets: all),
      ];
      expect(pickUpdate(releases, current, 'macos')!.tag, 'v0.0.19');
      expect(pickUpdate(releases, current, 'windows')!.tag, 'v0.0.20');
    });

    test('ignores drafts, pre-releases, older and equal versions', () {
      final releases = [
        release('v0.0.21', assets: all, draft: true),
        release('v0.0.20', assets: all, pre: true),
        release('v0.0.18', assets: all),
        release('v0.0.17', assets: all),
      ];
      expect(pickUpdate(releases, current, 'linux'), isNull);
    });

    test('unknown OS gets nothing', () {
      expect(pickUpdate([release('v1.0.0', assets: all)], current, 'fuchsia'), isNull);
    });
  });

  test('releasesBetween: newer than current up to the target, newest first', () {
    final releases = [
      release('v0.0.19', assets: all),
      release('v0.0.21', assets: all),
      release('v0.0.20', assets: all),
      release('v0.0.18', assets: all),
    ];
    final notes = releasesBetween(releases, AppVersion.tryParse('0.0.18')!, AppVersion.tryParse('0.0.20')!);
    expect(notes.map((r) => r.tag), ['v0.0.20', 'v0.0.19']);
  });

  group('changelog', () {
    const md = '## Unreleased\n\n- next\n\n## 0.0.18\n\n- icons\n- preview\n\n## 0.0.17\r\n\r\n- logcat\r\n';

    test('splits sections in file order and trims blank lines', () {
      final entries = parseChangelog(md);
      expect(entries.map((e) => e.title), ['Unreleased', '0.0.18', '0.0.17']);
      expect(entries[1].lines, ['- icons', '- preview']);
      expect(entries[2].lines, ['- logcat']);
      expect(entries[0].version, isNull);
      expect(entries[1].version, AppVersion.tryParse('0.0.18'));
    });

    test('release notes drop their own version heading', () {
      expect(releaseNoteLines('## 0.0.18\n\n- icons\n'), ['- icons']);
      expect(releaseNoteLines('- plain notes\n- no heading'), ['- plain notes', '- no heading']);
    });
  });

  test('UpdatePrefs round-trips', () {
    const prefs = UpdatePrefs(skippedVersion: '0.0.19', lastSeenVersion: '0.0.18');
    final back = UpdatePrefs.fromJson(prefs.toJson());
    expect(back.skippedVersion, '0.0.19');
    expect(back.lastSeenVersion, '0.0.18');
    expect(UpdatePrefs.fromJson(const {}).skippedVersion, isNull);
  });
}
