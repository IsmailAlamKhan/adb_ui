import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

final commandQueueControllerProvider =
    StateNotifierProvider<CommandQueueController, List<CommandModel>>(CommandQueueController.new);

/// Activity: every command run through `AdbController.run`, newest first.
///
/// stdout/stderr only feed the live output. The final state is set by [complete] or [fail]
/// from the command's `Result.messege` (spec/features/error-handling.md).
class CommandQueueController extends StateNotifier<List<CommandModel>> {
  final CommandQueueService service;
  CommandQueueController(Ref ref)
      : service = ref.read(commandQueueServiceProvider),
        super([]);

  final _subscriptions = <String, List<StreamSubscription<String>>>{};
  final _live = <String, ValueNotifier<String>>{};
  final _broadcast = <String, StreamController<String>>{};

  /// Output so far of a running command (empty notifier for unknown ids).
  ValueListenable<String> liveOutput(String id) => _live[id] ?? ValueNotifier('');

  CommandModel? byId(String id) {
    for (final command in state) {
      if (command.id == id) return command;
    }
    return null;
  }

  void addCommand(CommandModel command) {
    command.whenAdding((adding) {
      final live = ValueNotifier<String>('');
      final controller = StreamController<String>.broadcast();
      void append(String chunk) {
        live.value = live.value + chunk;
        if (!controller.isClosed) controller.add(chunk);
      }

      _live[adding.id] = live;
      _broadcast[adding.id] = controller;
      _subscriptions[adding.id] = [
        adding.stdout.listen(append, onError: (_) {}),
        adding.stderr.listen(append, onError: (_) {}),
      ];
      command = command.toRunning(controller.stream);
    });
    state = [command, ...state];
  }

  /// Marks [id] done. Output is what the process printed, or [message] if it printed nothing.
  Future<void> complete(String id, String message) async {
    final command = byId(id);
    if (command == null) return;
    final output = _output(id);
    final done = command.toDone(output.trim().isEmpty ? message : output);
    _replace(done);
    _dispose(id);
    await service.saveCommand(done);
  }

  /// Marks [id] failed. The stored error is the exception text followed by the output.
  Future<void> fail(String id, Object error) async {
    final command = byId(id);
    if (command == null) return;
    final message = exceptionToString(error);
    final output = _output(id).trim();
    final text = output.isEmpty || message.contains(output) ? message : '$message\n\n$output';
    final failed = command.toError(text);
    _replace(failed);
    _dispose(id);
    await service.saveCommand(failed);
  }

  String _output(String id) => _live[id]?.value ?? '';

  void _replace(CommandModel command) {
    state = [for (final c in state) c.id == command.id ? command : c];
  }

  void updateCommand(CommandModel command) => _replace(command);

  void removeCommand(CommandModel command) {
    state = state.where((element) => element.id != command.id).toList();
    _dispose(command.id);
    service.removeCommand(command);
  }

  void clear() {
    state = state.where((c) => !c.isDone).toList();
    service.clear();
  }

  void _dispose(String id) {
    for (final subscription in _subscriptions.remove(id) ?? const []) {
      subscription.cancel();
    }
    _broadcast.remove(id)?.close();
    // Not disposed: open views may still listen. The final text is in the model.
    _live.remove(id);
  }

  Future<void> init() => service.getCommands().then((value) {
        final list = value.toList()..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        state = list;
      });

  @override
  void dispose() {
    for (final id in _subscriptions.keys.toList()) {
      _dispose(id);
    }
    super.dispose();
  }
}
