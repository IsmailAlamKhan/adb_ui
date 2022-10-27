import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../features.dart';

class CommandQueueView extends HookConsumerWidget {
  const CommandQueueView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(commandQueueControllerProvider);
    // final running = queue
    //     .where((element) => element.whenOrNull(running: (_, __, ___, ____) => true) ?? false)
    //     .toList();
    // final done = queue
    //     .where((element) => element.whenOrNull(done: (_, __, ___, ____) => true) ?? false)
    //     .toList();
    // final error = queue
    //     .where((element) => element.whenOrNull(error: (_, __, ___, ____) => true) ?? false)
    //     .toList();

    Widget child = Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(title: Text('Command Queue')),
          if (queue.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No commands in queue')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: queue.length,
                (context, index) {
                  final command = queue[index];
                  return ListTile(
                    title: Text(command.command),
                    leading: command.whenOrNull(
                      done: (_, __, ___, ____) => const Icon(Icons.check),
                      error: (_, __, ___, ____) => const Icon(Icons.error),
                      running: (_, __, ___, ____) => const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    subtitle: command.device != null ? Text(command.device!.id) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () =>
                          ref.read(commandQueueControllerProvider.notifier).removeCommand(command),
                    ),
                    onTap: () {
                      Navigator.of(context).adaptivePush(
                        (_) => CurrentCommandOutput(commandId: command.id),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
    if (isTabletSize(context)) {
      child = Center(
        child: SizedBox(
          width: 500,
          height: 500,
          child: Dialog(clipBehavior: Clip.antiAlias, child: child),
        ),
      );
    }
    return child;
  }
}
