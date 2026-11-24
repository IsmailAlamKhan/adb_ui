import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/services/local_storage.dart';
import 'agent_model.dart';

// ── Settings ────────────────────────────────────────────────────────────────

final agentSettingsServiceProvider =
    Provider<AgentSettingsService>(LocalStorageAgentSettingsServiceImpl.new);

abstract class AgentSettingsService {
  Future<AgentServerSettings> load();
  Future<void> save(AgentServerSettings settings);

  /// A new random access token (32 bytes, base64url).
  String newToken();
}

class LocalStorageAgentSettingsServiceImpl implements AgentSettingsService {
  LocalStorageAgentSettingsServiceImpl(Ref ref) : storage = ref.read(localStorageProvider);
  final LocalStorage storage;

  @override
  Future<AgentServerSettings> load() => storage.get<AgentServerSettings>(
        LocalStorageKeys.agentServer,
        defaultValue: AgentServerSettings.initial,
        fromJson: (json) => AgentServerSettings.fromJson((json as Map).cast<String, dynamic>()),
      );

  @override
  Future<void> save(AgentServerSettings settings) =>
      storage.set<AgentServerSettings>(LocalStorageKeys.agentServer, settings);

  @override
  String newToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

// ── MCP protocol (no I/O) ───────────────────────────────────────────────────

/// A tool offered to agents.
class McpTool {
  const McpTool({
    required this.name,
    required this.title,
    required this.description,
    this.properties = const {},
    this.required = const [],
    this.risky = false,
    this.readOnly = false,
  });

  final String name;
  final String title;
  final String description;

  /// JSON-schema `properties` of the input object.
  final Map<String, Object> properties;
  final List<String> required;

  /// Asks the user before running.
  final bool risky;
  final bool readOnly;

  Map<String, dynamic> toJson() => {
        'name': name,
        'title': title,
        'description': description,
        'inputSchema': {
          'type': 'object',
          'properties': properties,
          if (required.isNotEmpty) 'required': required,
        },
        'annotations': {
          'title': title,
          'readOnlyHint': readOnly,
          'destructiveHint': risky,
          'openWorldHint': false,
        },
      };
}

/// Result of a tool call: text and image blocks, `isError` for failures.
class McpToolResult {
  const McpToolResult(this.content, {this.isError = false});

  factory McpToolResult.text(String text) => McpToolResult([
        {'type': 'text', 'text': text}
      ]);

  factory McpToolResult.error(String text) => McpToolResult([
        {'type': 'text', 'text': text}
      ], isError: true);

  factory McpToolResult.image(Uint8List png, {String? caption}) => McpToolResult([
        if (caption != null) {'type': 'text', 'text': caption},
        {'type': 'image', 'data': base64Encode(png), 'mimeType': 'image/png'},
      ]);

  final List<Map<String, dynamic>> content;
  final bool isError;

  /// First text block, for logs and test-run steps.
  String get summary {
    for (final block in content) {
      if (block['type'] == 'text') {
        final text = block['text'] as String;
        final line = text.split('\n').first;
        return line.length > 200 ? '${line.substring(0, 200)}…' : line;
      }
    }
    return content.any((b) => b['type'] == 'image') ? 'image' : '';
  }

  Map<String, dynamic> toJson() => {'content': content, 'isError': isError};
}

/// What the MCP server exposes.
abstract class McpToolbox {
  List<McpTool> get tools;
  Future<McpToolResult> call(String name, Map<String, dynamic> arguments);
}

/// JSON-RPC 2.0 handling for MCP (initialize, ping, tools/list, tools/call).
class McpProtocol {
  McpProtocol(this.toolbox, {this.serverName = 'adb-ui', this.serverVersion = '0.0.0'});

  final McpToolbox toolbox;
  final String serverName;
  final String serverVersion;

  static const supportedVersions = ['2024-11-05', '2025-03-26', '2025-06-18', '2025-11-25'];
  static const defaultVersion = '2025-06-18';

  static const parseError = -32700;
  static const invalidRequest = -32600;
  static const methodNotFound = -32601;
  static const invalidParams = -32602;

  /// Handles a request body. Returns the JSON response, or null when nothing is owed
  /// (notifications and responses only).
  Future<Object?> handleBody(String body) async {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return _error(null, parseError, 'Parse error');
    }
    if (decoded is List) {
      if (decoded.isEmpty) return _error(null, invalidRequest, 'Empty batch');
      final responses = <Object>[];
      for (final message in decoded) {
        final response = await handle(message);
        if (response != null) responses.add(response);
      }
      return responses.isEmpty ? null : responses;
    }
    return handle(decoded);
  }

  /// Handles one JSON-RPC message.
  Future<Map<String, dynamic>?> handle(Object? message) async {
    if (message is! Map || message['jsonrpc'] != '2.0') {
      return _error(message is Map ? message['id'] : null, invalidRequest, 'Invalid request');
    }
    final id = message['id'];
    final method = message['method'];
    final isNotification = !message.containsKey('id');
    if (method is! String) return isNotification ? null : _error(id, invalidRequest, 'Invalid request');
    if (isNotification) return null;
    final params = message['params'] is Map ? (message['params'] as Map).cast<String, dynamic>() : <String, dynamic>{};

    switch (method) {
      case 'initialize':
        final requested = params['protocolVersion'];
        return _result(id, {
          'protocolVersion': supportedVersions.contains(requested) ? requested : defaultVersion,
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {'name': serverName, 'title': 'ADB UI', 'version': serverVersion},
          'instructions': 'Controls Android devices through ADB UI. Every adb command shows in the '
              "app's Activity. Risky tools (install, uninstall, clear data, shell, push, pull) ask the "
              'user first. For UI tests: ui_dump or screenshot to see the screen, then tap_element / '
              'wait_for_element / assert_element; wrap a test in start_test_run and end_test_run.',
        });
      case 'ping':
        return _result(id, {});
      case 'tools/list':
        return _result(id, {'tools': [for (final tool in toolbox.tools) tool.toJson()]});
      case 'tools/call':
        final name = params['name'];
        if (name is! String) return _error(id, invalidParams, 'Missing tool name');
        if (!toolbox.tools.any((t) => t.name == name)) {
          return _error(id, invalidParams, 'Unknown tool: $name');
        }
        final args = params['arguments'] is Map
            ? (params['arguments'] as Map).cast<String, dynamic>()
            : <String, dynamic>{};
        McpToolResult result;
        try {
          result = await toolbox.call(name, args);
        } catch (e) {
          result = McpToolResult.error('$e');
        }
        return _result(id, result.toJson());
      default:
        return _error(id, methodNotFound, 'Method not found: $method');
    }
  }

  static Map<String, dynamic> _result(Object? id, Map<String, dynamic> result) =>
      {'jsonrpc': '2.0', 'id': id, 'result': result};

  static Map<String, dynamic> _error(Object? id, int code, String message) =>
      {'jsonrpc': '2.0', 'id': id, 'error': {'code': code, 'message': message}};
}

// ── HTTP server ─────────────────────────────────────────────────────────────

final mcpServerProvider = Provider<McpServer>((ref) {
  final server = McpHttpServerImpl();
  ref.onDispose(server.stop);
  return server;
});

/// The local MCP endpoint (spec/features/agent-mcp-server.md → MCP transport).
abstract class McpServer {
  bool get isRunning;

  /// Port actually bound (useful when started with port 0).
  int? get port;

  /// Binds 127.0.0.1:[port]. Throws [McpServerException] when it can't.
  Future<void> start({required int port, required String token, required McpProtocol protocol});

  Future<void> stop();
}

class McpServerException implements Exception {
  McpServerException(this.message);
  final String message;
  @override
  String toString() => message;
}

class McpHttpServerImpl implements McpServer {
  HttpServer? _server;
  String _token = '';
  McpProtocol? _protocol;

  @override
  bool get isRunning => _server != null;

  @override
  int? get port => _server?.port;

  @override
  Future<void> start({required int port, required String token, required McpProtocol protocol}) async {
    await stop();
    if (token.isEmpty) throw McpServerException('No access token.');
    _token = token;
    _protocol = protocol;
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _server = server;
      server.listen(_handle, onError: (_) {});
    } on SocketException catch (e) {
      throw McpServerException(
        e.osError?.errorCode == 48 || e.osError?.errorCode == 98 || e.osError?.errorCode == 10048
            ? 'Port $port is in use. Pick another port.'
            : "Couldn't start the server on port $port: ${e.osError?.message ?? e.message}",
      );
    }
  }

  @override
  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  bool _hostAllowed(HttpRequest request) {
    final host = request.headers.value(HttpHeaders.hostHeader);
    if (host == null) return false;
    final port = _server?.port;
    return host == '127.0.0.1:$port' || host == 'localhost:$port';
  }

  static bool _originAllowed(String? origin) {
    if (origin == null) return true;
    final uri = Uri.tryParse(origin);
    return uri != null && (uri.host == 'localhost' || uri.host == '127.0.0.1');
  }

  bool _authorized(HttpRequest request) {
    final header = request.headers.value(HttpHeaders.authorizationHeader) ?? '';
    const prefix = 'Bearer ';
    if (!header.startsWith(prefix)) return false;
    return _constantTimeEquals(header.substring(prefix.length).trim(), _token);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      if (!_hostAllowed(request) || !_originAllowed(request.headers.value('origin'))) {
        return await _send(response, HttpStatus.forbidden, 'Forbidden');
      }
      if (request.uri.path != '/mcp') return await _send(response, HttpStatus.notFound, 'Not found');
      if (!_authorized(request)) {
        response.headers.set(HttpHeaders.wwwAuthenticateHeader, 'Bearer');
        return await _send(response, HttpStatus.unauthorized, 'Missing or wrong access token');
      }
      if (request.method != 'POST') {
        response.headers.set(HttpHeaders.allowHeader, 'POST');
        return await _send(response, HttpStatus.methodNotAllowed, 'Use POST');
      }
      final body = await utf8.decoder.bind(request).join();
      final reply = await _protocol!.handleBody(body);
      if (reply == null) return await _send(response, HttpStatus.accepted, '');
      response.statusCode = HttpStatus.ok;
      response.headers.contentType = ContentType.json;
      response.write(jsonEncode(reply));
      await response.close();
    } catch (_) {
      try {
        await _send(response, HttpStatus.internalServerError, 'Internal error');
      } catch (_) {}
    }
  }

  static Future<void> _send(HttpResponse response, int status, String text) async {
    response.statusCode = status;
    if (text.isNotEmpty) {
      response.headers.contentType = ContentType.text;
      response.write(text);
    }
    await response.close();
  }
}

// ── Test-run recorder ───────────────────────────────────────────────────────

final agentRunRecorderProvider = Provider<AgentRunRecorder>((ref) => FileAgentRunRecorderImpl());

/// Saves agent test runs to `<app support>/agent_runs/<yyyyMMdd-HHmmss>-<name>/`.
abstract class AgentRunRecorder {
  String? get activeName;

  Future<String> runsFolder();

  /// Starts a run; an active run is ended as `abandoned` first. Returns its folder.
  Future<String> start(String name);

  Future<void> addStep(AgentRunStep step, {Uint8List? screenshot});

  /// Writes `run.json` and `report.md`; returns the folder, or null with no active run.
  Future<String?> end({required String status, String notes = ''});
}

class FileAgentRunRecorderImpl implements AgentRunRecorder {
  FileAgentRunRecorderImpl({this.baseFolder});

  /// Overrides the app-support location (tests).
  final String? baseFolder;

  String? _name;
  String? _folder;
  DateTime? _startedAt;
  final _steps = <AgentRunStep>[];

  @override
  String? get activeName => _name;

  @override
  Future<String> runsFolder() async {
    final base = baseFolder ?? (await getApplicationSupportDirectory()).path;
    final dir = Directory(p.join(base, 'agent_runs'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Future<String> start(String name) async {
    if (_name != null) await end(status: 'abandoned');
    final now = DateTime.now();
    final stamp = '${now.year}${_two(now.month)}${_two(now.day)}-${_two(now.hour)}${_two(now.minute)}${_two(now.second)}';
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final folder = p.join(await runsFolder(), slug.isEmpty ? stamp : '$stamp-$slug');
    await Directory(folder).create(recursive: true);
    _name = name;
    _folder = folder;
    _startedAt = now;
    _steps.clear();
    return folder;
  }

  @override
  Future<void> addStep(AgentRunStep step, {Uint8List? screenshot}) async {
    final folder = _folder;
    if (folder == null) return;
    var recorded = step;
    if (screenshot != null) {
      final file = 'step-${(_steps.length + 1).toString().padLeft(3, '0')}.png';
      await File(p.join(folder, file)).writeAsBytes(screenshot);
      recorded = AgentRunStep(
        at: step.at,
        tool: step.tool,
        arguments: step.arguments,
        ok: step.ok,
        summary: step.summary,
        screenshot: file,
      );
    }
    _steps.add(recorded);
  }

  @override
  Future<String?> end({required String status, String notes = ''}) async {
    final folder = _folder;
    final name = _name;
    if (folder == null || name == null) return null;
    final endedAt = DateTime.now();
    final json = {
      'name': name,
      'status': status,
      'notes': notes,
      'startedAt': _startedAt!.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'steps': [for (final s in _steps) s.toJson()],
    };
    await File(p.join(folder, 'run.json')).writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    final report = StringBuffer()
      ..writeln('# $name — ${status.toUpperCase()}')
      ..writeln()
      ..writeln('${_startedAt!.toIso8601String()} → ${endedAt.toIso8601String()}, ${_steps.length} steps')
      ..writeln();
    if (notes.isNotEmpty) report..writeln(notes)..writeln();
    for (var i = 0; i < _steps.length; i++) {
      final s = _steps[i];
      final args = s.arguments.isEmpty ? '' : ' `${jsonEncode(s.arguments)}`';
      report.writeln('${i + 1}. ${s.ok ? '✅' : '❌'} **${s.tool}**$args — ${s.summary}');
      if (s.screenshot != null) report.writeln('   ![](${s.screenshot})');
    }
    await File(p.join(folder, 'report.md')).writeAsString(report.toString());
    _name = null;
    _folder = null;
    _startedAt = null;
    _steps.clear();
    return folder;
  }
}
