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
      adding: (id, command, device, stdout, stderr) {
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
        updateCommand(CommandModel.running(
          id: id,
          command: command,
          device: device,
          output: streamController.stream,
        ));
        streamController.add('Running: $command');
      },
      running: (id, _command, device, output) {
        final buffer = StringBuffer();
        final subscription = output.listen(
          (event) {
            buffer.writeln(event);

            if (event.contains('Done')) {
              updateCommand(
                CommandModel.done(
                  id: id,
                  command: _command,
                  device: device,
                  output: buffer.toString(),
                ),
              );
              stopSubscription(id);
            }
          },
          onError: (error) {
            updateCommand(
              CommandModel.error(
                id: id,
                command: _command,
                device: device,
                error: error.toString(),
              ),
            );
            stopSubscription(id);
          },
        );
        outputSubscriptions[id] = subscription;
      },
      error: (id, command, device, error) => stopSubscription(id),
      done: (id, command, device, output) => stopSubscription(id),
    );
  }

  @override
  void dispose() {
    stopAllSubscriptions();
    super.dispose();
  }
}
