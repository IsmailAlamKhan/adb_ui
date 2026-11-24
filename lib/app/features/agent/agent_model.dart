import 'package:flutter/foundation.dart';

import '../../shared/services/local_storage.dart';

/// Saved under `LocalStorageKeys.agentServer`. See spec/features/agent-mcp-server.md.
@immutable
class AgentServerSettings with LocalStorageModel {
  const AgentServerSettings({this.enabled = false, this.port = defaultPort, this.token = ''});

  static const defaultPort = 47123;
  static const initial = AgentServerSettings();

  final bool enabled;
  final int port;
  final String token;

  String get url => 'http://127.0.0.1:$port/mcp';

  /// One line to add the server to Claude Code.
  String get claudeCodeCommand =>
      'claude mcp add --transport http adb-ui $url --header "Authorization: Bearer $token"';

  /// An `mcpServers` entry for other MCP clients.
  String get jsonConfig => '{\n'
      '  "mcpServers": {\n'
      '    "adb-ui": {\n'
      '      "type": "http",\n'
      '      "url": "$url",\n'
      '      "headers": { "Authorization": "Bearer $token" }\n'
      '    }\n'
      '  }\n'
      '}';

  AgentServerSettings copyWith({bool? enabled, int? port, String? token}) => AgentServerSettings(
        enabled: enabled ?? this.enabled,
        port: port ?? this.port,
        token: token ?? this.token,
      );

  @override
  Map<String, dynamic> toJson() => {'enabled': enabled, 'port': port, 'token': token};

  factory AgentServerSettings.fromJson(Map<String, dynamic> json) => AgentServerSettings(
        enabled: json['enabled'] == true,
        port: json['port'] is int ? json['port'] as int : defaultPort,
        token: json['token'] is String ? json['token'] as String : '',
      );

  @override
  bool operator ==(Object other) =>
      other is AgentServerSettings &&
      other.enabled == enabled &&
      other.port == port &&
      other.token == token;

  @override
  int get hashCode => Object.hash(enabled, port, token);
}

/// State of `agentControllerProvider`.
@immutable
class AgentState {
  const AgentState({
    this.settings = AgentServerSettings.initial,
    this.running = false,
    this.error,
    this.allowRiskyForSession = false,
    this.activeRun,
  });

  final AgentServerSettings settings;
  final bool running;

  /// Why the server isn't running, when it should be.
  final String? error;

  /// The user ticked "Allow risky actions until ADB UI quits".
  final bool allowRiskyForSession;

  /// Name of the test run being recorded, if any.
  final String? activeRun;

  String get status {
    if (running) return 'Listening on ${settings.url}';
    return error ?? 'Stopped';
  }

  AgentState copyWith({
    AgentServerSettings? settings,
    bool? running,
    String? error,
    bool clearError = false,
    bool? allowRiskyForSession,
    String? activeRun,
    bool clearActiveRun = false,
  }) =>
      AgentState(
        settings: settings ?? this.settings,
        running: running ?? this.running,
        error: clearError ? null : (error ?? this.error),
        allowRiskyForSession: allowRiskyForSession ?? this.allowRiskyForSession,
        activeRun: clearActiveRun ? null : (activeRun ?? this.activeRun),
      );
}

/// Answer of the risky-action dialog.
enum AgentConfirmChoice { deny, allowOnce, allowForSession }

// ── UI hierarchy (uiautomator dump) ─────────────────────────────────────────

/// One `<node>` of a `uiautomator dump`.
@immutable
class UiNode {
  const UiNode({
    required this.index,
    this.className = '',
    this.text = '',
    this.resourceId = '',
    this.contentDesc = '',
    this.packageName = '',
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
    this.clickable = false,
    this.enabled = true,
    this.focused = false,
    this.checked = false,
    this.selected = false,
    this.scrollable = false,
  });

  /// Position in document order (0-based), stable within one dump.
  final int index;
  final String className;
  final String text;
  final String resourceId;
  final String contentDesc;
  final String packageName;
  final int left;
  final int top;
  final int right;
  final int bottom;
  final bool clickable;
  final bool enabled;
  final bool focused;
  final bool checked;
  final bool selected;
  final bool scrollable;

  int get centerX => (left + right) ~/ 2;
  int get centerY => (top + bottom) ~/ 2;
  bool get hasSize => right > left && bottom > top;

  /// Worth listing in a compact dump: has a label or id, or reacts to input.
  bool get isUseful =>
      text.isNotEmpty || contentDesc.isNotEmpty || resourceId.isNotEmpty || clickable || scrollable;

  String get shortClass => className.split('.').last;

  /// One line for agents: `[12] Button "Sign in" id=login desc="…" (540,1200) [l,t][r,b] clickable`.
  String describe() {
    final parts = <String>['[$index]', shortClass.isEmpty ? 'node' : shortClass];
    if (text.isNotEmpty) parts.add('"${_oneLine(text)}"');
    if (resourceId.isNotEmpty) parts.add('id=$resourceId');
    if (contentDesc.isNotEmpty) parts.add('desc="${_oneLine(contentDesc)}"');
    parts.add('center=($centerX,$centerY)');
    parts.add('bounds=[$left,$top][$right,$bottom]');
    if (clickable) parts.add('clickable');
    if (scrollable) parts.add('scrollable');
    if (!enabled) parts.add('disabled');
    if (focused) parts.add('focused');
    if (checked) parts.add('checked');
    if (selected) parts.add('selected');
    return parts.join(' ');
  }

  static String _oneLine(String s) => s.replaceAll('\n', r'\n');

  static final _node = RegExp(r'<node\s([^>]*?)/?>');
  static final _attribute = RegExp(r'([\w-]+)="([^"]*)"');
  static final _bounds = RegExp(r'\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]');

  /// Parses the XML of `uiautomator dump`. Text before `<?xml` (the "dumped to" line) is ignored.
  static List<UiNode> parseDump(String xml) {
    final nodes = <UiNode>[];
    var index = 0;
    for (final match in _node.allMatches(xml)) {
      final a = <String, String>{};
      for (final attr in _attribute.allMatches(match.group(1)!)) {
        a[attr.group(1)!] = _unescape(attr.group(2)!);
      }
      final b = _bounds.firstMatch(a['bounds'] ?? '');
      int at(int i) => b == null ? 0 : int.parse(b.group(i)!);
      nodes.add(UiNode(
        index: index++,
        className: a['class'] ?? '',
        text: a['text'] ?? '',
        resourceId: a['resource-id'] ?? '',
        contentDesc: a['content-desc'] ?? '',
        packageName: a['package'] ?? '',
        left: at(1),
        top: at(2),
        right: at(3),
        bottom: at(4),
        clickable: a['clickable'] == 'true',
        enabled: a['enabled'] != 'false',
        focused: a['focused'] == 'true',
        checked: a['checked'] == 'true',
        selected: a['selected'] == 'true',
        scrollable: a['scrollable'] == 'true',
      ));
    }
    return nodes;
  }

  static String _unescape(String s) => s
      .replaceAllMapped(RegExp(r'&#(x?)([0-9a-fA-F]+);'), (m) {
        final code = int.tryParse(m.group(2)!, radix: m.group(1)!.isEmpty ? 10 : 16);
        return code == null ? m.group(0)! : String.fromCharCode(code);
      })
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&');
}

/// Finds [UiNode]s. Every field that is set must match (AND).
@immutable
class UiSelector {
  const UiSelector({this.text, this.textContains, this.resourceId, this.contentDesc, this.className});

  /// Exact text (case-sensitive).
  final String? text;

  /// Text or content-desc containing this, ignoring case.
  final String? textContains;

  /// Full id (`com.app:id/login`) or the part after `:id/` (`login`).
  final String? resourceId;

  /// Exact content-desc.
  final String? contentDesc;

  /// Full class name or its last part (`Button`).
  final String? className;

  static String? _str(Object? v) => v is String && v.isNotEmpty ? v : null;

  factory UiSelector.fromArgs(Map<String, dynamic> args) => UiSelector(
        text: _str(args['text']),
        textContains: _str(args['text_contains']),
        resourceId: _str(args['resource_id']),
        contentDesc: _str(args['content_desc']),
        className: _str(args['class_name']),
      );

  bool get isEmpty =>
      text == null && textContains == null && resourceId == null && contentDesc == null && className == null;

  bool matches(UiNode n) {
    if (text != null && n.text != text) return false;
    if (textContains != null) {
      final needle = textContains!.toLowerCase();
      if (!n.text.toLowerCase().contains(needle) && !n.contentDesc.toLowerCase().contains(needle)) {
        return false;
      }
    }
    if (resourceId != null && n.resourceId != resourceId && !n.resourceId.endsWith(':id/$resourceId')) {
      return false;
    }
    if (contentDesc != null && n.contentDesc != contentDesc) return false;
    if (className != null && n.className != className && n.shortClass != className) return false;
    return true;
  }

  List<UiNode> find(List<UiNode> nodes) => nodes.where(matches).toList();

  @override
  String toString() => [
        if (text != null) 'text="$text"',
        if (textContains != null) 'text_contains="$textContains"',
        if (resourceId != null) 'resource_id="$resourceId"',
        if (contentDesc != null) 'content_desc="$contentDesc"',
        if (className != null) 'class_name="$className"',
      ].join(' ');
}

// ── Test runs ───────────────────────────────────────────────────────────────

/// One tool call while a test run records.
@immutable
class AgentRunStep {
  const AgentRunStep({
    required this.at,
    required this.tool,
    required this.arguments,
    required this.ok,
    required this.summary,
    this.screenshot,
  });

  final DateTime at;
  final String tool;
  final Map<String, dynamic> arguments;
  final bool ok;
  final String summary;

  /// File name of the screenshot in the run folder.
  final String? screenshot;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'tool': tool,
        'arguments': arguments,
        'ok': ok,
        'summary': summary,
        if (screenshot != null) 'screenshot': screenshot,
      };
}
