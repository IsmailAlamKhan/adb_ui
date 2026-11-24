import 'dart:async';

import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../../design/design.dart';
import '../../utils/utils.dart';
import '../features.dart';

final agentControllerProvider =
    StateNotifierProvider<AgentController, AgentState>(AgentController.new);

/// AI agent access: runs the local MCP server and asks before risky tools
/// (spec/features/agent-mcp-server.md).
class AgentController extends StateNotifier<AgentState> with NavigationController {
  AgentController(this.ref)
      : eventBus = ref.read(eventBusProvider),
        settingsService = ref.read(agentSettingsServiceProvider),
        server = ref.read(mcpServerProvider),
        recorder = ref.read(agentRunRecorderProvider),
        super(const AgentState());

  final Ref ref;
  @override
  final EventBus eventBus;
  final AgentSettingsService settingsService;
  final McpServer server;
  final AgentRunRecorder recorder;

  late final AgentToolbox toolbox = AgentToolbox(
    service: ref.read(adbServiceProvider),
    runInActivity: _runInActivity,
    confirm: _confirm,
    recorder: recorder,
    onRunChanged: (name) {
      if (mounted) state = name == null ? state.copyWith(clearActiveRun: true) : state.copyWith(activeRun: name);
    },
  );

  /// Loads the settings and starts the server if it was on. Never throws.
  Future<void> init() async {
    try {
      state = state.copyWith(settings: await settingsService.load());
      if (state.settings.enabled) await _start();
    } catch (e, s) {
      logError('Could not start AI agent access', error: e, stackTrace: s);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    var settings = state.settings.copyWith(enabled: enabled);
    if (enabled && settings.token.isEmpty) settings = settings.copyWith(token: settingsService.newToken());
    await _save(settings);
    if (enabled) {
      await _start();
    } else {
      await server.stop();
      state = state.copyWith(running: false, clearError: true);
    }
  }

  /// Saves [port] and restarts the server if it's on. Returns an error text for bad input.
  Future<String?> applyPort(String value) async {
    final port = int.tryParse(value.trim());
    if (port == null || port < 1024 || port > 65535) return 'Use a port from 1024 to 65535.';
    await _save(state.settings.copyWith(port: port));
    if (state.settings.enabled) await _start();
    return null;
  }

  Future<void> newToken() async {
    await _save(state.settings.copyWith(token: settingsService.newToken()));
    if (state.settings.enabled) await _start();
    showToast(
      tone: ToastTone.info,
      title: 'New access token',
      message: 'Agents using the old token must be set up again.',
    );
  }

  void copyToken() => _copy(state.settings.token, 'Copied the access token');

  void copyClaudeCodeCommand() => _copy(state.settings.claudeCodeCommand, 'Copied the Claude Code command');

  void copyJsonConfig() => _copy(state.settings.jsonConfig, 'Copied the MCP config');

  void askAgainForRisky() => state = state.copyWith(allowRiskyForSession: false);

  Future<void> openRunsFolder() async {
    final folder = await recorder.runsFolder();
    if (!await launchUrl(Uri.file(folder))) {
      showToast(tone: ToastTone.info, title: 'Test runs are in', message: folder);
    }
  }

  // ── Internals ────────────────────────────────────────────────────────────

  Future<void> _save(AgentServerSettings settings) async {
    await settingsService.save(settings);
    state = state.copyWith(settings: settings);
  }

  Future<void> _start() async {
    final settings = state.settings;
    try {
      await server.start(
        port: settings.port,
        token: settings.token,
        protocol: McpProtocol(
          toolbox,
          serverVersion: ref.read(packageInfoControllerProvider)?.version ?? '0.0.0',
        ),
      );
      state = state.copyWith(running: true, clearError: true);
      logInfo('AI agent access listening on ${settings.url}');
    } on McpServerException catch (e) {
      state = state.copyWith(running: false, error: e.message);
    }
  }

  void _copy(String text, String title) {
    Clipboard.setData(ClipboardData(text: text));
    showToast(tone: ToastTone.success, title: title);
  }

  Future<String> _runInActivity(String label, Future<Result> Function() run) async {
    Object? error;
    final message = await ref
        .read(adbControllerProvider)
        .runForResult(
          command: 'Agent · $label',
          showOutput: false,
          function: () async {
            try {
              final result = await run();
              return result.copyWith(
                messege: result.messege.catchError((Object e, StackTrace s) {
                  error = e;
                  return Future<String>.error(e, s);
                }),
              );
            } catch (e) {
              error = e;
              rethrow;
            }
          },
        )
        .timeout(
          _commandTimeout,
          onTimeout: () => throw AgentToolException(
            '$label got no answer from adb in ${_commandTimeout.inSeconds}s. Check the device connection.',
          ),
        );
    if (message == null) {
      throw AgentToolException(error == null ? '$label failed.' : exceptionToString(error!));
    }
    return message;
  }

  static const _commandTimeout = Duration(seconds: 60);

  Future<void> _confirmQueue = Future.value();

  /// One dialog at a time; later requests wait for earlier ones.
  Future<bool> _confirm(String action, String details) {
    final answer = _confirmQueue.then((_) async {
      if (state.allowRiskyForSession) return true;
      await _bringToFront();
      final choice = await showDialog<AgentConfirmChoice>(
        barrierDismissible: false,
        pageBuilder: (_) => AgentConfirmDialog(action: action, details: details),
      );
      if (choice == AgentConfirmChoice.allowForSession && mounted) {
        state = state.copyWith(allowRiskyForSession: true);
      }
      return choice == AgentConfirmChoice.allowOnce || choice == AgentConfirmChoice.allowForSession;
    });
    _confirmQueue = answer.then((_) {}, onError: (_) {});
    return answer;
  }

  /// A covered window doesn't repaint, so the dialog would go unseen: show and focus it.
  Future<void> _bringToFront() async {
    try {
      await windowManager.ensureInitialized();
      if (await windowManager.isMinimized()) await windowManager.restore();
      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      logError('Could not bring the window to the front', error: e);
    }
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }
}
