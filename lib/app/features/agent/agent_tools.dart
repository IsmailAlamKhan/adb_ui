import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../adb/adb_model.dart';
import '../adb/adb_service.dart';
import '../logcat/logcat_model.dart';
import 'agent_model.dart';
import 'agent_service.dart';

/// A tool failed in a way the agent should read (shown as a tool error).
class AgentToolException implements Exception {
  AgentToolException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Runs an adb [Result] through Activity under [label]; returns its message or throws
/// [AgentToolException] with the failure.
typedef AgentActivityRunner = Future<String> Function(String label, Future<Result> Function() run);

/// Asks the user before a risky tool. True = allowed.
typedef AgentConfirm = Future<bool> Function(String action, String details);

/// The MCP tools (spec/features/agent-mcp-server.md → Tools).
class AgentToolbox implements McpToolbox {
  AgentToolbox({
    required this.service,
    required this.runInActivity,
    required this.confirm,
    required this.recorder,
    required this.onRunChanged,
  });

  final AdbService service;
  final AgentActivityRunner runInActivity;
  final AgentConfirm confirm;
  final AgentRunRecorder recorder;
  final void Function(String? activeRun) onRunChanged;

  static const _dumpPath = '/sdcard/.adb_ui_dump.xml';

  // ── Schemas ──────────────────────────────────────────────────────────────

  static const Map<String, Object> _deviceProp = {
    'device': {
      'type': 'string',
      'description': 'adb serial from list_devices. Optional when only one device is connected.',
    },
  };

  static const Map<String, Object> _selectorProps = {
    'text': {'type': 'string', 'description': 'Exact text.'},
    'text_contains': {'type': 'string', 'description': 'Text or content-desc containing this (any case).'},
    'resource_id': {'type': 'string', 'description': 'Resource id, full (com.app:id/login) or short (login).'},
    'content_desc': {'type': 'string', 'description': 'Exact content description.'},
    'class_name': {'type': 'string', 'description': 'Class, full or short (Button).'},
  };

  static Map<String, Object> _props(Map<String, Object> extra, {bool selector = false}) => {
        ..._deviceProp,
        if (selector) ..._selectorProps,
        ...extra,
      };

  static const _package = {'package': {'type': 'string', 'description': 'Package name, e.g. com.example.app.'}};

  @override
  late final List<McpTool> tools = [
    const McpTool(
      name: 'list_devices',
      title: 'List devices',
      description: 'Connected Android devices: serial, state and model.',
      readOnly: true,
    ),
    McpTool(
      name: 'device_info',
      title: 'Device info',
      description: 'Model, manufacturer, Android version, SDK, ABI and screen size.',
      properties: _props({}),
      readOnly: true,
    ),
    McpTool(
      name: 'list_packages',
      title: 'List packages',
      description: 'Installed package names (third-party only unless include_system).',
      properties: _props({
        'include_system': {'type': 'boolean', 'description': 'Include system packages.'},
      }),
      readOnly: true,
    ),
    McpTool(
      name: 'install_apk',
      title: 'Install APK',
      description: 'Install an .apk from a path on this computer. The user is asked first. '
          "Installs to the phone's current user (the personal profile) unless user is given.",
      properties: _props({
        'path': {'type': 'string', 'description': 'Absolute path to the .apk on this computer.'},
        'user': {
          'type': ['integer', 'string'],
          'description': 'Optional profile: a user id from `pm list users` (e.g. 10 for a work '
              'profile) or "all" for every profile.',
        },
      }),
      required: ['path'],
      risky: true,
    ),
    McpTool(
      name: 'uninstall_app',
      title: 'Uninstall app',
      description: 'Uninstall a package. The user is asked first.',
      properties: _props(_package),
      required: ['package'],
      risky: true,
    ),
    McpTool(
      name: 'launch_app',
      title: 'Launch app',
      description: "Start a package's launcher activity.",
      properties: _props(_package),
      required: ['package'],
    ),
    McpTool(
      name: 'stop_app',
      title: 'Force-stop app',
      description: 'Force-stop a package (am force-stop).',
      properties: _props(_package),
      required: ['package'],
    ),
    McpTool(
      name: 'clear_app_data',
      title: 'Clear app data',
      description: "Delete a package's data (pm clear). The user is asked first.",
      properties: _props(_package),
      required: ['package'],
      risky: true,
    ),
    McpTool(
      name: 'screenshot',
      title: 'Screenshot',
      description: 'PNG of the device screen. Coordinates in it are device pixels, as used by tap.',
      properties: _props({}),
      readOnly: true,
    ),
    McpTool(
      name: 'tap',
      title: 'Tap',
      description: 'Tap at device pixel coordinates.',
      properties: _props({
        'x': {'type': 'integer'},
        'y': {'type': 'integer'},
      }),
      required: ['x', 'y'],
    ),
    McpTool(
      name: 'swipe',
      title: 'Swipe',
      description: 'Swipe from (x1,y1) to (x2,y2) over duration_ms (default 300).',
      properties: _props({
        'x1': {'type': 'integer'},
        'y1': {'type': 'integer'},
        'x2': {'type': 'integer'},
        'y2': {'type': 'integer'},
        'duration_ms': {'type': 'integer'},
      }),
      required: ['x1', 'y1', 'x2', 'y2'],
    ),
    McpTool(
      name: 'type_text',
      title: 'Type text',
      description: 'Type text into the focused field, as if typed.',
      properties: _props({
        'text': {'type': 'string'},
      }),
      required: ['text'],
    ),
    McpTool(
      name: 'press_key',
      title: 'Press key',
      description: 'Press a key: back, home, enter, recents, delete, tab, escape, power, volume_up, '
          'volume_down, menu, search, or any KEYCODE_* name or number.',
      properties: _props({
        'key': {'type': 'string'},
      }),
      required: ['key'],
    ),
    McpTool(
      name: 'shell',
      title: 'Shell command',
      description: 'Run `adb shell <command>` and return its output. The user is asked first.',
      properties: _props({
        'command': {'type': 'string'},
      }),
      required: ['command'],
      risky: true,
    ),
    McpTool(
      name: 'logcat',
      title: 'Read logcat',
      description: 'Recent device log, filtered like the Logcat screen. Use clear before a test step '
          'to read only what that step logged.',
      properties: _props({
        'lines': {'type': 'integer', 'description': 'Lines to read before filtering (default 300, max 5000).'},
        'preset': {
          'type': 'string',
          'enum': ['all', 'warnings', 'errors', 'crashes'],
        },
        'package': {'type': 'string', 'description': 'Only lines from this running app.'},
        'min_level': {
          'type': 'string',
          'enum': ['verbose', 'debug', 'info', 'warn', 'error', 'fatal'],
        },
        'text': {'type': 'string', 'description': 'Only lines whose tag or message contains this.'},
        'clear': {'type': 'boolean', 'description': 'Clear the device log after reading.'},
      }),
      readOnly: true,
    ),
    McpTool(
      name: 'list_files',
      title: 'List files',
      description: 'List a folder on the device. Folders end with /.',
      properties: _props({
        'path': {'type': 'string', 'description': 'Default /sdcard/.'},
      }),
      readOnly: true,
    ),
    McpTool(
      name: 'pull_file',
      title: 'Pull file',
      description: 'Copy a device file to a path on this computer. The user is asked first.',
      properties: _props({
        'device_path': {'type': 'string'},
        'local_path': {'type': 'string'},
      }),
      required: ['device_path', 'local_path'],
      risky: true,
    ),
    McpTool(
      name: 'push_file',
      title: 'Push file',
      description: 'Copy a file from this computer to a device path. The user is asked first.',
      properties: _props({
        'local_path': {'type': 'string'},
        'device_path': {'type': 'string', 'description': 'Destination folder or file on the device.'},
      }),
      required: ['local_path', 'device_path'],
      risky: true,
    ),
    // UI testing
    McpTool(
      name: 'ui_dump',
      title: 'Dump UI',
      description: 'View hierarchy of the screen (uiautomator), one line per element with text, '
          'resource id, content-desc, center and bounds. Cheaper than a screenshot for finding things.',
      properties: _props({
        'all': {'type': 'boolean', 'description': 'List every node, not only labelled/clickable ones.'},
      }),
      readOnly: true,
    ),
    McpTool(
      name: 'find_elements',
      title: 'Find elements',
      description: 'Elements matching a selector (all given fields must match).',
      properties: _props({}, selector: true),
      readOnly: true,
    ),
    McpTool(
      name: 'tap_element',
      title: 'Tap element',
      description: 'Tap the center of the element matching a selector.',
      properties: _props({
        'nth': {'type': 'integer', 'description': 'Which match to tap when several (0-based, default 0).'},
      }, selector: true),
    ),
    McpTool(
      name: 'wait_for_element',
      title: 'Wait for element',
      description: 'Wait until an element matching the selector appears (or, with gone, disappears).',
      properties: _props({
        'gone': {'type': 'boolean'},
        'timeout_ms': {'type': 'integer', 'description': 'Default 10000, max 60000.'},
      }, selector: true),
      readOnly: true,
    ),
    McpTool(
      name: 'assert_element',
      title: 'Assert element',
      description: 'Check the screen once. expect: exists (default), gone, or text_equals (with '
          'expected_text). A failure is a tool error starting with FAIL:.',
      properties: _props({
        'expect': {
          'type': 'string',
          'enum': ['exists', 'gone', 'text_equals'],
        },
        'expected_text': {'type': 'string'},
      }, selector: true),
      readOnly: true,
    ),
    const McpTool(
      name: 'start_test_run',
      title: 'Start test run',
      description: 'Start recording a test run: every later tool call becomes a step, screenshots are saved.',
      properties: {
        'name': {'type': 'string'},
      },
      required: ['name'],
    ),
    const McpTool(
      name: 'end_test_run',
      title: 'End test run',
      description: 'Stop recording and write run.json and report.md. Returns the folder.',
      properties: {
        'status': {
          'type': 'string',
          'enum': ['passed', 'failed'],
        },
        'notes': {'type': 'string'},
      },
      required: ['status'],
    ),
  ];

  late final Map<String, McpTool> _byName = {for (final t in tools) t.name: t};

  // ── Dispatch ─────────────────────────────────────────────────────────────

  @override
  Future<McpToolResult> call(String name, Map<String, dynamic> args) async {
    Uint8List? shot;
    McpToolResult result;
    try {
      result = await _dispatch(name, args, (png) => shot = png);
    } on AgentToolException catch (e) {
      result = McpToolResult.error(e.message);
    } catch (e) {
      result = McpToolResult.error('$e');
    }
    if (recorder.activeName != null && name != 'start_test_run') {
      await recorder.addStep(
        AgentRunStep(at: DateTime.now(), tool: name, arguments: args, ok: !result.isError, summary: result.summary),
        screenshot: shot,
      );
    }
    return result;
  }

  Future<McpToolResult> _dispatch(String name, Map<String, dynamic> a, void Function(Uint8List) onShot) async {
    final tool = _byName[name];
    if (tool == null) throw AgentToolException('Unknown tool: $name');

    switch (name) {
      case 'list_devices':
        final devices = await service.getConnectedDevices().timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw AgentToolException('adb devices got no answer in 20s. Is adb stuck?'),
            );
        if (devices.isEmpty) return McpToolResult.text('No devices connected.');
        return McpToolResult.text(devices
            .map((d) => '${d.id}\t${d.type}${d.model.isEmpty ? '' : '\t${d.model}'}')
            .join('\n'));
      case 'start_test_run':
        final folder = await recorder.start(_req(a, 'name'));
        onRunChanged(recorder.activeName);
        return McpToolResult.text('Recording "${a['name']}" to $folder');
      case 'end_test_run':
        final folder = await recorder.end(status: _req(a, 'status'), notes: _str(a, 'notes') ?? '');
        onRunChanged(null);
        if (folder == null) throw AgentToolException('No test run is recording.');
        return McpToolResult.text('Saved the run to $folder (run.json, report.md).');
    }

    final device = await _device(a);
    final label = '${tool.title}${_short(a)}';

    if (tool.risky) {
      final details = _riskDetails(name, a, device);
      if (!await confirm(_riskAction[name] ?? tool.title.toLowerCase(), details)) {
        throw AgentToolException('The user denied this action.');
      }
    }

    switch (name) {
      case 'device_info':
        final props = await service.deviceProperties(device);
        final size = await _shell(device, 'Screen size', ['shell', 'wm', 'size']);
        final values = props.raw;
        String v(String k) => values[k] ?? '';
        return McpToolResult.text([
          'serial: ${device.id}',
          'model: ${v('ro.product.model')}',
          'manufacturer: ${v('ro.product.manufacturer')}',
          'android: ${v('ro.build.version.release')} (SDK ${v('ro.build.version.sdk')})',
          'abi: ${v('ro.product.cpu.abi')}',
          size.trim(),
        ].join('\n'));
      case 'list_packages':
        final packages = await service.listPackages(device, includeSystem: a['include_system'] == true);
        return McpToolResult.text(packages.isEmpty ? 'No packages.' : packages.join('\n'));
      case 'install_apk':
        final path = _req(a, 'path');
        if (!File(path).existsSync()) throw AgentToolException('No file at $path');
        final user = _installUser(a['user']);
        return McpToolResult.text(
          await runInActivity(label, () => service.installApk(device, path, user: user ?? 'current')),
        );
      case 'uninstall_app':
        final package = _req(a, 'package');
        return McpToolResult.text(await runInActivity(label, () => service.uninstallApp(device, package)));
      case 'launch_app':
        final package = _req(a, 'package');
        await _shell(device, label, [
          'shell',
          'monkey -p $package -c android.intent.category.LAUNCHER 1',
        ]);
        return McpToolResult.text('Launched $package');
      case 'stop_app':
        await _shell(device, label, ['shell', 'am', 'force-stop', _req(a, 'package')]);
        return McpToolResult.text('Stopped ${a['package']}');
      case 'clear_app_data':
        return McpToolResult.text(await _shell(device, label, ['shell', 'pm', 'clear', _req(a, 'package')]));
      case 'screenshot':
        Uint8List? png;
        final message = await runInActivity(label, () => service.screenshot(device, (b) => png = b));
        onShot(png!);
        return McpToolResult.image(png!, caption: message);
      case 'tap':
        final x = _int(a, 'x'), y = _int(a, 'y');
        await _shell(device, 'Tap $x,$y', ['shell', 'input', 'tap', '$x', '$y']);
        return McpToolResult.text('Tapped $x,$y');
      case 'swipe':
        final c = [_int(a, 'x1'), _int(a, 'y1'), _int(a, 'x2'), _int(a, 'y2')];
        final ms = _optInt(a, 'duration_ms') ?? 300;
        await _shell(device, 'Swipe ${c.join(',')}', ['shell', 'input', 'swipe', ...c.map((e) => '$e'), '$ms']);
        return McpToolResult.text('Swiped ${c[0]},${c[1]} → ${c[2]},${c[3]}');
      case 'type_text':
        final text = _req(a, 'text');
        await runInActivity('Type text', () => service.inputText(device, text));
        return McpToolResult.text('Typed ${text.length} characters');
      case 'press_key':
        final code = keyCode(_req(a, 'key'));
        await _shell(device, 'Press $code', ['shell', 'input', 'keyevent', code]);
        return McpToolResult.text('Pressed $code');
      case 'shell':
        final command = _req(a, 'command');
        final output = await _shell(device, 'shell $command', ['shell', command]);
        return McpToolResult.text(output == 'Done' ? '(no output)' : output);
      case 'logcat':
        return McpToolResult.text(await _logcat(device, a, label));
      case 'list_files':
        final path = _str(a, 'path') ?? '/sdcard/';
        final files = await service.ls(device, path);
        if (files.isEmpty) return McpToolResult.text('(empty)');
        return McpToolResult.text(files.map((f) => f is AdbDirectory ? '${f.name}/' : f.name).join('\n'));
      case 'pull_file':
        final from = _req(a, 'device_path'), to = _req(a, 'local_path');
        return McpToolResult.text(await runInActivity(label, () => service.pullFile(device, from, to)));
      case 'push_file':
        final from = _req(a, 'local_path'), to = _req(a, 'device_path');
        if (!File(from).existsSync()) throw AgentToolException('No file at $from');
        return McpToolResult.text(await runInActivity(label, () => service.pushFile(device, from, to)));
      case 'ui_dump':
        final nodes = await _dump(device);
        final shown = a['all'] == true ? nodes : nodes.where((n) => n.isUseful).toList();
        final package = nodes.map((n) => n.packageName).firstWhere((p) => p.isNotEmpty, orElse: () => '');
        return McpToolResult.text([
          '${shown.length} of ${nodes.length} elements${package.isEmpty ? '' : ' · $package'}',
          ...shown.map((n) => n.describe()),
        ].join('\n'));
      case 'find_elements':
        final selector = _selector(a);
        final found = selector.find(await _dump(device));
        if (found.isEmpty) return McpToolResult.text('No element matches $selector');
        return McpToolResult.text(['${found.length} match $selector', ...found.map((n) => n.describe())].join('\n'));
      case 'tap_element':
        final selector = _selector(a);
        final found = selector.find(await _dump(device));
        final nth = _optInt(a, 'nth') ?? 0;
        if (found.isEmpty) throw AgentToolException('No element matches $selector');
        if (nth < 0 || nth >= found.length) {
          throw AgentToolException('Only ${found.length} elements match $selector');
        }
        final node = found[nth];
        if (!node.hasSize) throw AgentToolException('The element has no size on screen: ${node.describe()}');
        await _shell(device, 'Tap ${node.shortClass} ${node.text.isEmpty ? node.resourceId : '"${node.text}"'}',
            ['shell', 'input', 'tap', '${node.centerX}', '${node.centerY}']);
        return McpToolResult.text('Tapped ${node.describe()}');
      case 'wait_for_element':
        return McpToolResult.text(await _waitFor(device, a));
      case 'assert_element':
        return _assert(device, a);
    }
    throw AgentToolException('Unknown tool: $name');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<String> _shell(AdbDevice device, String label, List<String> arguments) =>
      runInActivity(label, () => service.runArguments(device, arguments));

  Future<List<UiNode>> _dump(AdbDevice device) async {
    Future<List<UiNode>> once() async {
      var xml = '';
      await runInActivity(
        'Dump UI',
        () => service.runArguments(
          device,
          ['shell', 'uiautomator dump $_dumpPath >/dev/null && cat $_dumpPath'],
          onStdout: (out) => xml = out,
          summarize: (out) => 'UI dump: ${'<node '.allMatches(out).length} elements',
        ),
      );
      if (!xml.contains('<hierarchy')) throw AgentToolException("Couldn't read the screen's view hierarchy.");
      return UiNode.parseDump(xml);
    }

    try {
      return await once();
    } on AgentToolException {
      // uiautomator fails while the screen animates ("could not get idle state"): retry once.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return once();
    }
  }

  Future<String> _waitFor(AdbDevice device, Map<String, dynamic> a) async {
    final selector = _selector(a);
    final gone = a['gone'] == true;
    final timeout = Duration(milliseconds: (_optInt(a, 'timeout_ms') ?? 10000).clamp(0, 60000));
    final started = DateTime.now();
    while (true) {
      final found = selector.find(await _dump(device));
      final waited = DateTime.now().difference(started).inMilliseconds;
      if (gone && found.isEmpty) return 'Gone after ${waited}ms: $selector';
      if (!gone && found.isNotEmpty) return 'Found after ${waited}ms: ${found.first.describe()}';
      if (DateTime.now().difference(started) >= timeout) {
        throw AgentToolException(
          'Timed out after ${timeout.inMilliseconds}ms waiting for $selector to ${gone ? 'disappear' : 'appear'}.',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<McpToolResult> _assert(AdbDevice device, Map<String, dynamic> a) async {
    final selector = _selector(a);
    final expect = _str(a, 'expect') ?? 'exists';
    final found = selector.find(await _dump(device));
    switch (expect) {
      case 'exists':
        return found.isNotEmpty
            ? McpToolResult.text('PASS: ${found.first.describe()}')
            : McpToolResult.error('FAIL: no element matches $selector');
      case 'gone':
        return found.isEmpty
            ? McpToolResult.text('PASS: nothing matches $selector')
            : McpToolResult.error('FAIL: still on screen: ${found.first.describe()}');
      case 'text_equals':
        final expected = _req(a, 'expected_text', allowEmpty: true);
        if (found.isEmpty) return McpToolResult.error('FAIL: no element matches $selector');
        final actual = found.first.text;
        return actual == expected
            ? McpToolResult.text('PASS: text is "$expected"')
            : McpToolResult.error('FAIL: expected "$expected", found "$actual" in ${found.first.describe()}');
    }
    throw AgentToolException('expect must be exists, gone or text_equals.');
  }

  Future<String> _logcat(AdbDevice device, Map<String, dynamic> a, String label) async {
    final lines = (_optInt(a, 'lines') ?? 300).clamp(1, 5000);
    var output = '';
    await runInActivity(
      'Read logcat',
      () => service.runArguments(
        device,
        ['logcat', '-d', '-v', 'threadtime', '-t', '$lines'],
        onStdout: (out) => output = out,
        summarize: (out) => '${'\n'.allMatches(out).length} log lines',
      ),
    );
    final preset = LogPreset.values.firstWhere((p) => p.name == _str(a, 'preset'), orElse: () => LogPreset.all);
    final minLevel = LogLevel.values.where((l) => l.name == _str(a, 'min_level')).firstOrNull;
    final filter = LogcatFilter(preset: preset, minLevel: minLevel, text: _str(a, 'text') ?? '');
    final package = _str(a, 'package');
    Set<int>? pids;
    if (package != null) {
      pids = await service.pidsOf(device, package);
      if (pids.isEmpty) throw AgentToolException('$package is not running.');
    }
    final tracker = CrashTracker();
    var seq = 0;
    final kept = output
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !l.startsWith('--------- beginning of'))
        .map((l) => tracker.mark(LogcatEntry.parse(l.trimRight(), seq++)))
        .where((e) => filter.matches(e, pids: pids))
        .map((e) => e.raw)
        .toList();
    if (a['clear'] == true) await runInActivity('Clear logcat', () => service.clearLogcat(device));
    if (kept.isEmpty) return 'No matching log lines (read $seq).';
    return '${kept.length} of $seq lines\n${kept.join('\n')}';
  }

  Future<AdbDevice> _device(Map<String, dynamic> a) async {
    final wanted = _str(a, 'device');
    final devices = await service.getConnectedDevices().timeout(
          const Duration(seconds: 20),
          onTimeout: () => throw AgentToolException('adb devices got no answer in 20s. Is adb stuck?'),
        );
    if (wanted != null) {
      for (final d in devices) {
        if (d.id == wanted) {
          if (!d.isOnline) throw AgentToolException('$wanted is ${d.type}.');
          return d;
        }
      }
      throw AgentToolException('No device $wanted. Connected: ${devices.map((d) => d.id).join(', ')}');
    }
    final online = devices.where((d) => d.isOnline).toList();
    if (online.isEmpty) throw AgentToolException('No device connected.');
    if (online.length > 1) {
      throw AgentToolException(
        'Several devices are connected; pass device: ${online.map((d) => d.id).join(', ')}',
      );
    }
    return online.single;
  }

  /// `install_apk`'s `user`: an id or `all`; null when not given.
  static String? _installUser(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (text == 'all' || int.tryParse(text) != null) return text;
    throw AgentToolException('user must be a user id (e.g. 10) or "all"');
  }

  /// Completes "Allow an AI agent to …?".
  static const _riskAction = {
    'install_apk': 'install an app',
    'uninstall_app': 'uninstall an app',
    'clear_app_data': "clear an app's data",
    'shell': 'run a shell command',
    'pull_file': 'copy a file from the device',
    'push_file': 'copy a file to the device',
  };

  static String _riskDetails(String name, Map<String, dynamic> a, AdbDevice device) {
    final on = 'on ${device.model.isEmpty ? device.id : device.model}';
    return switch (name) {
      'install_apk' => 'Install ${a['path']} $on${a['user'] == null ? '' : ' (user ${a['user']})'}',
      'uninstall_app' => 'Uninstall ${a['package']} and its data $on',
      'clear_app_data' => 'Delete all data of ${a['package']} $on',
      'shell' => 'Run `adb shell ${a['command']}` $on',
      'pull_file' => 'Copy ${a['device_path']} $on to ${a['local_path']} on this computer',
      'push_file' => 'Copy ${a['local_path']} from this computer to ${a['device_path']} $on',
      _ => '$name $on',
    };
  }

  static String _short(Map<String, dynamic> a) {
    final v = a['package'] ?? a['path'] ?? a['device_path'];
    return v is String && v.isNotEmpty ? ' $v' : '';
  }

  static UiSelector _selector(Map<String, dynamic> a) {
    final selector = UiSelector.fromArgs(a);
    if (selector.isEmpty) {
      throw AgentToolException('Give at least one of text, text_contains, resource_id, content_desc, class_name.');
    }
    return selector;
  }

  static String? _str(Map<String, dynamic> a, String key) {
    final v = a[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  static String _req(Map<String, dynamic> a, String key, {bool allowEmpty = false}) {
    final v = a[key];
    if (v is String && (allowEmpty || v.isNotEmpty)) return v;
    throw AgentToolException('Missing "$key".');
  }

  static int? _optInt(Map<String, dynamic> a, String key) {
    final v = a[key];
    if (v is int) return v;
    if (v is num) return v.round();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static int _int(Map<String, dynamic> a, String key) =>
      _optInt(a, key) ?? (throw AgentToolException('Missing "$key".'));

  static const _keys = {
    'back': 'KEYCODE_BACK',
    'home': 'KEYCODE_HOME',
    'enter': 'KEYCODE_ENTER',
    'recents': 'KEYCODE_APP_SWITCH',
    'app_switch': 'KEYCODE_APP_SWITCH',
    'delete': 'KEYCODE_DEL',
    'backspace': 'KEYCODE_DEL',
    'tab': 'KEYCODE_TAB',
    'escape': 'KEYCODE_ESCAPE',
    'power': 'KEYCODE_POWER',
    'volume_up': 'KEYCODE_VOLUME_UP',
    'volume_down': 'KEYCODE_VOLUME_DOWN',
    'menu': 'KEYCODE_MENU',
    'search': 'KEYCODE_SEARCH',
  };

  /// `input keyevent` argument for a friendly name, `KEYCODE_*` or number.
  static String keyCode(String key) {
    final k = key.trim();
    final named = _keys[k.toLowerCase()];
    if (named != null) return named;
    if (int.tryParse(k) != null) return k;
    final upper = k.toUpperCase();
    if (RegExp(r'^KEYCODE_[A-Z0-9_]+$').hasMatch(upper)) return upper;
    if (RegExp(r'^[A-Z0-9_]+$').hasMatch(upper)) return 'KEYCODE_$upper';
    throw AgentToolException('Unknown key "$key".');
  }
}
