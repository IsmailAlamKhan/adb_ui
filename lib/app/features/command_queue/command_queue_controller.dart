import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

final commandQueueControllerProvider =
    StateNotifierProvider<CommandQueueController, List<CommandModel>>(CommandQueueController.new);

class CommandQueueController extends StateNotifier<List<CommandModel>> {
  CommandQueueController(Ref ref) : super([]);

  final outputSubscriptions = <String, StreamSubscription>{};
  final outputControllers = <String, StreamController>{};

  void addCommand(CommandModel command) {
    state = [command, ...state];
    listenAndChangeCommand(command);
  }

  void removeCommand(CommandModel command) {
    state = state.where((element) => element.id != command.id).toList();
  }

  void clear() {
    state = [];
    stopAllSubscriptions();
  }

  void updateCommand(CommandModel command) {
    state = state.map((element) => element.id == command.id ? command : element).toList();
    listenAndChangeCommand(command);
  }

  void stopAllSubscriptions() {
    outputSubscriptions.forEach((key, value) => value.cancel());
    outputSubscriptions.clear();
    outputControllers.forEach((key, value) => value.close());
    outputControllers.clear();
  }

  void stopSubscription(String id) {
    outputSubscriptions[id]?.cancel();
    outputSubscriptions.remove(id);
    outputControllers[id]?.close();
    outputControllers.remove(id);
  }

  void listenAndChangeCommand(CommandModel command) {
    command.whenOrNull(
      adding: (id, _command, __, stdout, stderr, ___, ____) {
        final streamController = StreamController<String>.broadcast();

        final stdoutSubscription = stdout.listen(
          streamController.add,
          onDone: () {
            if (!streamController.isClosed) {
              streamController.add('Done');
            }
          },
        );
        final stderrSubscription = stderr.listen(streamController.addError);
        streamController.onCancel = () {
          stdoutSubscription.cancel();
          stderrSubscription.cancel();
        };
        outputControllers[id] = streamController;
        updateCommand(command.toRunning(streamController.stream));
        streamController.add('Running: $_command');
      },
      running: (id, _command, device, output, _, __) {
        final buffer = StringBuffer();
        final subscription = output.listen(
          (event) {
            buffer.writeln(event);

            if (event.contains('Done')) {
              updateCommand(command.toDone(buffer.toString()));
              stopSubscription(id);
            }
          },
          onError: (error) {
            buffer.writeln(error);
            updateCommand(command.toError(buffer.toString()));
            stopSubscription(id);
          },
        );
        outputSubscriptions[id] = subscription;
      },
      error: (id, _, __, ___, ____, _____) => stopSubscription(id),
      done: (id, _, __, ___, ____, _____) => stopSubscription(id),
    );
  }

  @override
  void dispose() {
    stopAllSubscriptions();
    super.dispose();
  }
}
