import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
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
                    Widget? leading;
                    command.whenDone((_) => leading = const Icon(Icons.check));
                    command.whenError((_) => leading = const Icon(Icons.error));
                    command.whenRunning(
                      (p0) => leading = const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
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
                      leading: leading,
                      subtitle: _Subtitle(command: command),
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

class _Subtitle extends HookWidget {
  const _Subtitle({super.key, required this.command});

  final CommandModel command;

  @override
  Widget build(BuildContext context) {
    String? device = command.device?.model;
    final startedIn = 'Started ${command.startedAt.timeAgoSinceNow()}';
    String? finishedIn = command.finishedIn?.let((it) => 'Finished in ${it}ms');
    if (finishedIn != null && device != null) {
      return Text('$startedIn | $finishedIn\n$device ');
    }
    if (finishedIn != null) {
      return Text('$startedIn | $finishedIn');
    }
    if (device != null) {
      return Text('$startedIn | $device');
    }
    return Text(startedIn);
  }
}
