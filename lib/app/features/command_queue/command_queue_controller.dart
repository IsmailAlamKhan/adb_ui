import 'dart:async';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

final commandQueueControllerProvider =
    StateNotifierProvider<CommandQueueController, List<CommandModel>>(CommandQueueController.new);

class CommandQueueController extends StateNotifier<List<CommandModel>> {
  final CommandQueueService service;
  CommandQueueController(Ref ref)
      : service = ref.read(commandQueueServiceProvider),
        super([]);

  final outputSubscriptions = <String, StreamSubscription>{};
  final outputControllers = <String, StreamController>{};

  void addCommand(CommandModel command) {
    state = [command, ...state];
    listenAndChangeCommand(command);
  }

  void removeCommand(CommandModel command) {
    state = state.where((element) => element.id != command.id).toList();
    service.removeCommand(command);
  }

  void clear() {
    state = [];
    stopAllSubscriptions();
    service.clear();
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
      adding: (id, _command, __, stdout, stderr, ___, ____, _) {
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
      running: (id, _command, device, output, _, __, ___) {
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
      // error: (id, _, __, ___, ____, _____) => stopSubscription(id),
      // done: (id, _, __, ___, ____, _____) => stopSubscription(id),
    );

    command.whenError((command) {
      stopSubscription(command.id);
      service.saveCommand(command);
    });
    command.whenDone((command) {
      stopSubscription(command.id);
      service.saveCommand(command);
    });
  }

  Future<void> init() {
    return service.getCommands().then((value) => state = value);
  }

  @override
  void dispose() {
    stopAllSubscriptions();
    super.dispose();
  }
}
