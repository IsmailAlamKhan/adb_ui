import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../features.dart';

class CommandQueueView extends HookConsumerWidget {
  const CommandQueueView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(commandQueueControllerProvider);
    final controller = ref.watch(commandQueueControllerProvider.notifier);

    return AdaptiveDialog(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Command Queue'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.clear_all),
                  onPressed: () => controller.clear(),
                ),
              ],
            ),
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
                      title: Text.rich(
                        TextSpan(
                          text: command.command,
                          children: [
                            if (command.isRerun)
                              TextSpan(
                                text: ' (rerun)',
                                style: Theme.of(context).textTheme.caption,
                              ),
                          ],
                        ),
                      ),
                      leading: command.whenOrNull(
                        done: (_, __, ___, ____, _____, ______) => const Icon(Icons.check),
                        error: (_, __, ___, ____, _____, ______) => const Icon(Icons.error),
                        running: (_, __, ___, ____, _____, ______) => const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      subtitle: command.device != null ? Text(command.device!.model) : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cancel),
                            onPressed: () => ref
                                .read(commandQueueControllerProvider.notifier)
                                .removeCommand(command),
                          ),
                          if (command.isDone)
                            IconButton(
                              tooltip: 'Re-run',
                              icon: const Icon(Icons.replay),
                              onPressed: () => ref
                                  .read(adbControllerProvider) //
                                  .rerunCommand(command),
                            ),
                        ],
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
      ),
    );
  }
}
