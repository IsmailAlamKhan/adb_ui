import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:adb_ui/app/features/agent/agent_model.dart';
import 'package:adb_ui/app/features/agent/agent_service.dart';
import 'package:adb_ui/app/features/agent/agent_tools.dart';
import 'package:flutter_test/flutter_test.dart';

const _dump = '''UI hierchary dumped to: /sdcard/.adb_ui_dump.xml
<?xml version='1.0' encoding='UTF-8' standalone='yes' ?><hierarchy rotation="0"><node index="0" text="" resource-id="" class="android.widget.FrameLayout" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="false" enabled="true" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][1080,2400]"><node index="0" text="Sign in" resource-id="com.example.app:id/login" class="android.widget.Button" package="com.example.app" content-desc="" checkable="false" checked="false" clickable="true" enabled="true" focusable="true" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[100,1000][980,1200]" /><node index="1" text="Tom &amp; Jerry&#10;line" resource-id="" class="android.widget.TextView" package="com.example.app" content-desc="Greeting" checkable="false" checked="false" clickable="false" enabled="false" focusable="false" focused="false" scrollable="false" long-clickable="false" password="false" selected="false" bounds="[0,0][540,100]" /></node></hierarchy>''';

class _FakeToolbox implements McpToolbox {
  final calls = <String>[];

  @override
  List<McpTool> get tools => const [
        McpTool(name: 'echo', title: 'Echo', description: 'Echoes', readOnly: true),
        McpTool(name: 'boom', title: 'Boom', description: 'Fails', risky: true),
      ];

  @override
  Future<McpToolResult> call(String name, Map<String, dynamic> arguments) async {
    calls.add(name);
    if (name == 'boom') throw StateError('exploded');
    return McpToolResult.text('echo ${arguments['v']}');
  }
}

void main() {
  group('UiNode.parseDump', () {
    final nodes = UiNode.parseDump(_dump);

    test('reads every node in document order with attributes', () {
      expect(nodes, hasLength(3));
      final button = nodes[1];
      expect(button.index, 1);
      expect(button.text, 'Sign in');
      expect(button.resourceId, 'com.example.app:id/login');
      expect(button.shortClass, 'Button');
      expect(button.clickable, isTrue);
      expect((button.left, button.top, button.right, button.bottom), (100, 1000, 980, 1200));
      expect((button.centerX, button.centerY), (540, 1100));
    });

    test('unescapes XML entities', () {
      expect(nodes[2].text, 'Tom & Jerry\nline');
      expect(nodes[2].enabled, isFalse);
    });

    test('describe is one line', () {
      expect(nodes[2].describe(), contains(r'"Tom & Jerry\nline"'));
      expect(nodes[2].describe(), contains('disabled'));
      expect(nodes[1].describe(), startsWith('[1] Button "Sign in" id=com.example.app:id/login'));
    });

    test('isUseful skips empty containers', () {
      expect(nodes.where((n) => n.isUseful).map((n) => n.index), [1, 2]);
    });
  });

  group('UiSelector', () {
    final nodes = UiNode.parseDump(_dump);

    test('short and full resource ids', () {
      expect(const UiSelector(resourceId: 'login').find(nodes).single.text, 'Sign in');
      expect(const UiSelector(resourceId: 'com.example.app:id/login').find(nodes), hasLength(1));
      expect(const UiSelector(resourceId: 'logi').find(nodes), isEmpty);
    });

    test('text is exact, text_contains ignores case and checks content-desc', () {
      expect(const UiSelector(text: 'sign in').find(nodes), isEmpty);
      expect(const UiSelector(textContains: 'SIGN').find(nodes), hasLength(1));
      expect(const UiSelector(textContains: 'greet').find(nodes).single.index, 2);
    });

    test('fields combine with AND; class by short name', () {
      expect(const UiSelector(className: 'Button', text: 'Sign in').find(nodes), hasLength(1));
      expect(const UiSelector(className: 'TextView', text: 'Sign in').find(nodes), isEmpty);
    });

    test('fromArgs ignores empty values', () {
      expect(UiSelector.fromArgs(const {'text': '', 'resource_id': null}).isEmpty, isTrue);
      expect(UiSelector.fromArgs(const {'text_contains': 'x'}).textContains, 'x');
    });
  });

  group('AgentToolbox.keyCode', () {
    test('maps names, keycodes and numbers', () {
      expect(AgentToolbox.keyCode('back'), 'KEYCODE_BACK');
      expect(AgentToolbox.keyCode('Recents'), 'KEYCODE_APP_SWITCH');
      expect(AgentToolbox.keyCode('keycode_camera'), 'KEYCODE_CAMERA');
      expect(AgentToolbox.keyCode('dpad_up'), 'KEYCODE_DPAD_UP');
      expect(AgentToolbox.keyCode('66'), '66');
      expect(() => AgentToolbox.keyCode('rm -rf'), throwsA(isA<AgentToolException>()));
    });
  });

  group('AgentServerSettings', () {
    test('JSON round trip and defaults', () {
      const s = AgentServerSettings(enabled: true, port: 5000, token: 'abc');
      expect(AgentServerSettings.fromJson(s.toJson()), s);
      expect(AgentServerSettings.fromJson(const {}), AgentServerSettings.initial);
      expect(s.claudeCodeCommand,
          'claude mcp add --transport http adb-ui http://127.0.0.1:5000/mcp --header "Authorization: Bearer abc"');
      expect(jsonDecode(s.jsonConfig)['mcpServers']['adb-ui']['url'], 'http://127.0.0.1:5000/mcp');
    });
  });

  group('McpProtocol', () {
    late _FakeToolbox toolbox;
    late McpProtocol protocol;
    setUp(() {
      toolbox = _FakeToolbox();
      protocol = McpProtocol(toolbox, serverVersion: '1.2.3');
    });

    Future<Map<String, dynamic>> rpc(String method, [Map<String, dynamic>? params]) async =>
        (await protocol.handle({'jsonrpc': '2.0', 'id': 7, 'method': method, 'params': ?params}))!;

    test('initialize echoes a supported version, else the default', () async {
      final ok = await rpc('initialize', {'protocolVersion': '2025-03-26'});
      expect(ok['id'], 7);
      expect(ok['result']['protocolVersion'], '2025-03-26');
      expect(ok['result']['serverInfo']['version'], '1.2.3');
      expect(ok['result']['capabilities']['tools'], isNotNull);
      final other = await rpc('initialize', {'protocolVersion': '1999-01-01'});
      expect(other['result']['protocolVersion'], McpProtocol.defaultVersion);
    });

    test('tools/list carries schema and hints', () async {
      final tools = (await rpc('tools/list'))['result']['tools'] as List;
      expect(tools.map((t) => t['name']), ['echo', 'boom']);
      expect(tools.first['inputSchema']['type'], 'object');
      expect(tools.last['annotations']['destructiveHint'], isTrue);
    });

    test('tools/call returns content; failures become isError results', () async {
      final ok = await rpc('tools/call', {
        'name': 'echo',
        'arguments': {'v': 1},
      });
      expect(ok['result']['content'][0]['text'], 'echo 1');
      expect(ok['result']['isError'], isFalse);
      final failed = await rpc('tools/call', {'name': 'boom'});
      expect(failed['result']['isError'], isTrue);
      expect(failed['result']['content'][0]['text'], contains('exploded'));
    });

    test('errors: unknown tool, unknown method, bad JSON, notifications', () async {
      expect((await rpc('tools/call', {'name': 'nope'}))['error']['code'], McpProtocol.invalidParams);
      expect((await rpc('resources/list'))['error']['code'], McpProtocol.methodNotFound);
      expect(((await protocol.handleBody('{oops')) as Map)['error']['code'], McpProtocol.parseError);
      expect(await protocol.handleBody('{"jsonrpc":"2.0","method":"notifications/initialized"}'), isNull);
      final batch = await protocol.handleBody('[{"jsonrpc":"2.0","id":1,"method":"ping"}]');
      expect(batch, [
        {'jsonrpc': '2.0', 'id': 1, 'result': <String, dynamic>{}}
      ]);
    });
  });

  group('McpHttpServerImpl', () {
    late McpHttpServerImpl server;
    late HttpClient client;
    setUp(() async {
      server = McpHttpServerImpl();
      await server.start(port: 0, token: 'secret', protocol: McpProtocol(_FakeToolbox()));
      client = HttpClient();
    });
    tearDown(() async {
      client.close(force: true);
      await server.stop();
    });

    Future<(int, String)> post(
      String body, {
      String? token = 'secret',
      String path = '/mcp',
      String method = 'POST',
      Map<String, String> headers = const {},
    }) async {
      final request = await client.openUrl(method, Uri.parse('http://127.0.0.1:${server.port}$path'));
      if (token != null) request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      headers.forEach(request.headers.set);
      request.write(body);
      final response = await request.close();
      return (response.statusCode, await utf8.decoder.bind(response).join());
    }

    const ping = '{"jsonrpc":"2.0","id":1,"method":"ping"}';

    test('answers an authorised POST with JSON', () async {
      final (status, body) = await post(ping);
      expect(status, 200);
      expect(jsonDecode(body)['result'], <String, dynamic>{});
    });

    test('rejects missing or wrong tokens', () async {
      expect((await post(ping, token: null)).$1, 401);
      expect((await post(ping, token: 'secreT')).$1, 401);
    });

    test('rejects foreign origins and hosts', () async {
      expect((await post(ping, headers: {'origin': 'https://evil.example'})).$1, 403);
      expect((await post(ping, headers: {'origin': 'http://localhost:3000'})).$1, 200);
      expect((await post(ping, headers: {'host': 'evil.example'})).$1, 403);
    });

    test('notifications get 202, GET gets 405, other paths 404', () async {
      expect((await post('{"jsonrpc":"2.0","method":"notifications/initialized"}')).$1, 202);
      expect((await post('', method: 'GET')).$1, 405);
      expect((await post(ping, path: '/other')).$1, 404);
    });

    test('stop frees the port', () async {
      final port = server.port!;
      await server.stop();
      expect(server.isRunning, isFalse);
      final again = await ServerSocket.bind(InternetAddress.loopbackIPv4, port);
      await again.close();
    });
  });

  group('FileAgentRunRecorderImpl', () {
    test('writes run.json, report.md and screenshots', () async {
      final dir = await Directory.systemTemp.createTemp('agent_runs_test');
      addTearDown(() => dir.delete(recursive: true));
      final recorder = FileAgentRunRecorderImpl(baseFolder: dir.path);
      final folder = await recorder.start('Login works');
      expect(recorder.activeName, 'Login works');
      expect(folder, contains('login-works'));
      await recorder.addStep(
        AgentRunStep(at: DateTime(2026), tool: 'screenshot', arguments: const {}, ok: true, summary: 'Screenshot'),
        screenshot: Uint8List.fromList([1, 2, 3]),
      );
      await recorder.addStep(
        AgentRunStep(at: DateTime(2026), tool: 'assert_element', arguments: const {'text': 'Hi'}, ok: false, summary: 'FAIL'),
      );
      expect(await recorder.end(status: 'failed', notes: 'button missing'), folder);
      expect(recorder.activeName, isNull);
      final json = jsonDecode(File('$folder/run.json').readAsStringSync()) as Map;
      expect(json['status'], 'failed');
      expect((json['steps'] as List).first['screenshot'], 'step-001.png');
      expect(File('$folder/step-001.png').existsSync(), isTrue);
      expect(File('$folder/report.md').readAsStringSync(), contains('# Login works — FAILED'));
      expect(await recorder.end(status: 'passed'), isNull);
    });
  });
}
