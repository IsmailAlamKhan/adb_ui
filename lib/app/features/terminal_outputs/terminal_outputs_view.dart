import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

class CurrentCommandOutput extends HookConsumerWidget {
  const CurrentCommandOutput({
    super.key,
    required this.commandId,
  });
  final String commandId;

  static const routeSettings = RouteSettings(name: '/terminal_outputs/current_command_output');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final command = ref.watch(commandQueueControllerProvider.select(
      (value) => value.firstWhere((element) => element.id == commandId),
    ));

    final content = command.maybeWhen<Widget>(
      running: (id, command, device, output, rawCommand, executable) =>
          _CommandRunning(output: output),
      error: (id, command, device, error, rawCommand, executable) => _CommandError(error: error),
      done: (id, command, device, output, rawCommand, executable) => _CommandDone(output: output),
      orElse: () => const Center(child: CircularProgressIndicator()),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: AlertDialog(
          scrollable: true,
          title: Text.rich(
            TextSpan(
              text: command.command,
              children: [
                if (command.device != null)
                  TextSpan(
                    text: ' on ${command.device!.model}',
                    style: Theme.of(context).textTheme.caption,
                  ),
              ],
            ),
          ),
          content: SelectionArea(child: content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandRunning extends HookConsumerWidget {
  const _CommandRunning({
    super.key,
    required this.output,
  });

  final Stream<String> output;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = useStream(output);
    if (snapshot.hasData) {
      return Text(snapshot.data!);
    } else if (snapshot.hasError) {
      return Text(snapshot.error.toString());
    } else {
      return const Text('Running...');
    }
  }
}

class _CommandError extends HookConsumerWidget {
  const _CommandError({
    super.key,
    required this.error,
  });
  final Object error;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(error.toString());
  }
}

class _CommandDone extends HookConsumerWidget {
  const _CommandDone({
    super.key,
    required this.output,
  });

  final String output;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(output);
  }
}
