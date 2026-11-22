import 'dart:typed_data';

import 'package:adb_ui/app/features/adb/adb_model.dart';
import 'package:adb_ui/app/features/ai/ai_filter_mapper.dart';
import 'package:adb_ui/app/features/logcat/logcat_model.dart';
import 'package:adb_ui/app/features/mirror/scrcpy_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogcatEntry.parse', () {
    test('threadtime lines (real samples from a Pixel)', () {
      final e = LogcatEntry.parse(
        '11-22 18:29:07.835 14766 14766 I pixel-thermal: VIRTUAL-USB-UI:0 raw data: VIRTUAL-USB-UI:0 ',
        1,
      );
      expect(e.parsed, isTrue);
      expect(e.time, '11-22 18:29:07.835');
      expect(e.pid, 14766);
      expect(e.level, LogLevel.info);
      expect(e.tag, 'pixel-thermal');
      expect(e.message, startsWith('VIRTUAL-USB-UI:0 raw data'));

      final padded = LogcatEntry.parse("11-22 18:29:07.843 24753 24753 I adbd    : adbd service requested 'shell'", 2);
      expect(padded.tag, 'adbd');
      expect(padded.message, "adbd service requested 'shell'");

      final empty = LogcatEntry.parse('11-22 18:29:07.835  1306  1334 W libPixelUsbOverheat:', 3);
      expect(empty.tag, 'libPixelUsbOverheat');
      expect(empty.message, '');
    });

    test('other lines are kept unparsed', () {
      final e = LogcatEntry.parse('--------- beginning of main', 1);
      expect(e.parsed, isFalse);
      expect(e.message, '--------- beginning of main');
    });
  });

  group('LogcatFilter', () {
    LogcatEntry line(String level, String tag, String msg, {int pid = 10}) =>
        LogcatEntry.parse('11-22 10:00:00.000 $pid $pid $level $tag: $msg', 0);

    test('presets, level, tags, text, regex and pids', () {
      final w = line('W', 'Net', 'timeout talking to http://x');
      final i = line('I', 'Net', 'ok');
      expect(const LogcatFilter(preset: LogPreset.warnings).matches(w), isTrue);
      expect(const LogcatFilter(preset: LogPreset.warnings).matches(i), isFalse);
      expect(const LogcatFilter(minLevel: LogLevel.error).matches(w), isFalse);
      expect(const LogcatFilter(includeTags: ['Net']).matches(i), isTrue);
      expect(const LogcatFilter(excludeTags: ['Net']).matches(i), isFalse);
      expect(const LogcatFilter(text: 'HTTP').matches(w), isTrue);
      expect(const LogcatFilter(text: r'timeout.*http', regex: true).matches(w), isTrue);
      expect(const LogcatFilter(text: '[bad', regex: true).matches(w), isFalse);
      expect(const LogcatFilter().matches(w, pids: {11}), isFalse);
      expect(const LogcatFilter().matches(w, pids: {10}), isTrue);
    });

    test('crash tracker marks the crash and its stack trace', () {
      final tracker = CrashTracker(traceLines: 2);
      final start = tracker.mark(line('E', 'AndroidRuntime', 'FATAL EXCEPTION: main'));
      final t1 = tracker.mark(line('E', 'AndroidRuntime', 'java.lang.NullPointerException'));
      final t2 = tracker.mark(line('E', 'AndroidRuntime', '  at com.example.Main'));
      final t3 = tracker.mark(line('E', 'AndroidRuntime', '  at more'));
      final other = tracker.mark(line('I', 'Foo', 'hello'));
      expect(start.crash, CrashMark.start);
      expect([t1.crash, t2.crash], [CrashMark.trace, CrashMark.trace]);
      expect(t3.crash, CrashMark.none);
      expect(other.crash, CrashMark.none);
      expect(const LogcatFilter(preset: LogPreset.crashes).matches(t1), isTrue);
      expect(tracker.mark(line('E', 'ActivityManager', 'ANR in com.example')).crash, CrashMark.start);
    });
  });

  test('foreground package and pids parsing', () {
    expect(
      parseForegroundPackage(
        '  ResumedActivity: ActivityRecord{89249477 u0 com.google.android.apps.nexuslauncher/.NexusLauncherActivity t2}',
      ),
      'com.google.android.apps.nexuslauncher',
    );
    expect(
      parseForegroundPackage('topResumedActivity=ActivityRecord{1a2b u0 com.Slack/slack.app.ui.HomeActivity t9}'),
      'com.Slack',
    );
    expect(parseForegroundPackage('nothing'), isNull);
    expect(parsePids('2830 4411\n'), {2830, 4411});
    expect(parsePids(''), isEmpty);
  });

  test('parseLsOutput: folders first, A–Z, root system entries hidden', () {
    final list = parseLsOutput('b.txt\nAlarms/\nandroid/\nA.jpg\nls: ./x: Permission denied\n');
    expect(list.map((e) => e.name), ['Alarms', 'android', 'A.jpg', 'b.txt']);
    expect(list.first, isA<AdbDirectory>());
    expect(parseLsOutput('sdcard/\nsystem/\nvendor/\n', root: true).map((e) => e.name), ['sdcard']);
  });

  group('AiFilterMapper', () {
    const packages = ['com.Slack', 'com.example.shop', 'com.google.android.gm'];

    test('maps fields and marks them as AI-set', () {
      final f = AiFilterMapper.toFilter({
        'preset': 'errors',
        'package': 'slack',
        'excludeTags': ['chatty'],
        'text': 'http',
        'explanation': 'Errors from Slack mentioning http',
      }, packages: packages);
      expect(f.preset, LogPreset.errors);
      expect(f.package, 'com.Slack');
      expect(f.excludeTags, ['chatty']);
      expect(f.text, 'http');
      expect(f.aiExplanation, 'Errors from Slack mentioning http');
      expect(f.aiFields, containsAll(['preset', 'package', 'excludeTags', 'text']));
    });

    test('drops unknown packages, bad levels and invalid regex', () {
      final f = AiFilterMapper.toFilter(
        {'package': 'com.not.installed', 'minLevel': 'X', 'text': '[oops', 'regex': true, 'explanation': ''},
        packages: packages,
      );
      expect(f.package, isNull);
      expect(f.minLevel, isNull);
      expect(f.regex, isFalse);
      expect(f.aiExplanation, isNull);
    });

    test('keeps the followed app when the model leaves package out', () {
      final f = AiFilterMapper.toFilter(
        {'preset': 'crashes', 'explanation': 'Crashes'},
        packages: packages,
        base: const LogcatFilter(package: 'com.example.shop'),
      );
      expect(f.package, 'com.example.shop');
      expect(f.preset, LogPreset.crashes);
    });

    test('guards against invented values (real outputs from the Fast model)', () {
      final slack = AiFilterMapper.toFilter({
        'explanation': 'Filter shows errors from the Slack app.',
        'preset': 'errors',
        'package': 'com.Slack',
        'minLevel': 'E',
        'includeTags': ['error', 'slack'],
        'text': 'Slack received an error.',
      }, packages: packages, request: 'errors from slack');
      expect(slack.package, 'com.Slack');
      expect(slack.preset, LogPreset.errors);
      expect(slack.minLevel, isNull);
      expect(slack.text, isEmpty);

      final crashes = AiFilterMapper.toFilter({
        'explanation': 'Crashes',
        'preset': 'crashes',
        'package': 'com.Slack',
        'minLevel': 'F',
        'includeTags': ['android:Crash'],
        'text': 'android:Crash',
      }, packages: packages, request: 'show me crashes');
      expect(crashes.preset, LogPreset.crashes);
      expect(crashes.package, isNull);
      expect(crashes.minLevel, isNull);
      expect(crashes.includeTags, isEmpty);
      expect(crashes.text, isEmpty);

      final hide = AiFilterMapper.toFilter({
        'explanation': 'Hides chatty',
        'includeTags': ['chatty', 'Choreographer'],
        'package': 'com.Slack',
      }, packages: packages, request: 'hide chatty and Choreographer logs');
      expect(hide.includeTags, isEmpty);
      expect(hide.excludeTags, ['chatty', 'Choreographer']);
      expect(hide.package, isNull);

      final mine = AiFilterMapper.toFilter(
        {'package': 'com.example.shop', 'text': 'timeout', 'explanation': 'x'},
        packages: packages,
        request: 'timeouts in my app',
        base: const LogcatFilter(package: 'com.example.shop'),
      );
      expect(mine.package, 'com.example.shop');
      expect(mine.text, 'timeout');
    });

    test('rules read presets, named apps and tags to hide', () {
      expect(AiFilterMapper.fromRules('errors from slack', packages: packages),
          {'preset': 'errors', 'package': 'com.Slack'});
      expect(AiFilterMapper.fromRules('show me crashes', packages: packages), {'preset': 'crashes'});
      expect(AiFilterMapper.fromRules('ANRs in gmail', packages: ['com.google.android.gm']),
          {'preset': 'crashes', 'text': 'gmail'});
      expect(AiFilterMapper.fromRules('network timeouts in whatsapp', packages: [...packages, 'com.whatsapp']),
          {'package': 'com.whatsapp', 'text': 'network|timeout', 'regex': true});
      expect(AiFilterMapper.fromRules('hide chatty and Choreographer logs', packages: packages),
          {'excludeTags': ['chatty', 'Choreographer']});
      expect(AiFilterMapper.fromRules('warnings in my app', packages: packages, followed: 'com.example.shop'),
          {'preset': 'warnings', 'package': 'com.example.shop'});
      // The model saying nothing still gives a useful filter.
      final f = AiFilterMapper.toFilter({'explanation': 'Errors from Slack'},
          packages: packages, request: 'errors from slack');
      expect(f.package, 'com.Slack');
      expect(f.preset, LogPreset.errors);
    });

    test('resolvePackage matches exact, last segment, or one unique substring', () {
      expect(AiFilterMapper.resolvePackage('com.slack', packages), 'com.Slack');
      expect(AiFilterMapper.resolvePackage('gm', packages), 'com.google.android.gm');
      expect(AiFilterMapper.resolvePackage('shop', packages), 'com.example.shop');
      expect(AiFilterMapper.resolvePackage('com', packages), isNull);
    });

    test('system prompt lists packages and the followed app', () {
      final prompt = AiFilterMapper.systemPrompt(packages: packages, followedPackage: 'com.Slack');
      expect(prompt, contains('com.google.android.gm'));
      expect(prompt, contains('Followed app: com.Slack'));
    });
  });

  group('ScrcpyControl byte layouts (scrcpy 4.0)', () {
    test('touch is 32 bytes with big-endian fields', () {
      final b = ByteData.sublistView(ScrcpyControl.touch(
        action: ScrcpyControl.actionDown,
        x: 100,
        y: 200,
        width: 1080,
        height: 2400,
      ));
      expect(b.lengthInBytes, 32);
      expect(b.getUint8(0), 2);
      expect(b.getUint8(1), 0);
      expect(b.getInt64(2), -2);
      expect(b.getInt32(10), 100);
      expect(b.getInt32(14), 200);
      expect(b.getUint16(18), 1080);
      expect(b.getUint16(20), 2400);
      expect(b.getUint16(22), 0xffff);
    });

    test('keycode 14 bytes, scroll 21, text and clipboard length-prefixed', () {
      final k = ByteData.sublistView(ScrcpyControl.keycode(action: 1, keycode: ScrcpyControl.keyHome));
      expect(k.lengthInBytes, 14);
      expect([k.getUint8(0), k.getUint8(1), k.getInt32(2)], [0, 1, 3]);

      final s = ByteData.sublistView(ScrcpyControl.scroll(x: 1, y: 2, width: 3, height: 4, vscroll: -16));
      expect(s.lengthInBytes, 21);
      expect(s.getUint8(0), 3);
      expect(s.getInt16(15), -0x8000);

      final t = ScrcpyControl.text('hé');
      expect(t[0], 1);
      expect(ByteData.sublistView(t).getUint32(1), 3);
      expect(t.length, 8);

      final c = ByteData.sublistView(ScrcpyControl.setClipboard('ab'));
      expect([c.getUint8(0), c.getUint8(9), c.getUint32(10)], [9, 1, 2]);
      expect(c.lengthInBytes, 16);

      expect(ScrcpyControl.rotate(), [11]);
      expect(ScrcpyControl.backOrScreenOn(0), [4, 0]);
      expect(ScrcpyControl.displayPower(false), [10, 0]);
    });
  });
}
