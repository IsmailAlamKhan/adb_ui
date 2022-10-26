import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
// class TerminalOutputsView extends HookConsumerWidget {
//   const TerminalOutputsView({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final outputs = ref.watch(terminalOutputsProvider);
//     final scrollController = useScrollController();
//     final autoScroll = useRef(false);

//     useEffect(
//       () {
//         if (autoScroll.value && scrollController.hasClients) {
//           scrollController.jumpTo(scrollController.position.maxScrollExtent);
//         }
//       },
//       [outputs],
//     );

//     useEffect(() {
//       scrollController.addListener(() {
//         if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
//           autoScroll.value = true;
//         }
//         if (scrollController.position.userScrollDirection == ScrollDirection.reverse &&
//             autoScroll.value) {
//           autoScroll.value = false;
//         }
//       });
//     }, []);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Terminal Outputs'),
//         actions: [
//           IconButton(
//             onPressed: () {
//               autoScroll.value = true;
//             },
//             icon: const Icon(Icons.unfold_more),
//           ),
//         ],
//       ),
//       body: ListView(
//         controller: scrollController,
//         children: [
//           for (var output in outputs) Text(output),
//         ],
//       ),
//     );
//   }
// }

class CurrentCommandOutput extends HookConsumerWidget {
  const CurrentCommandOutput({
    super.key,
    required this.stdoutStream,
    required this.stderrStream,
    required this.command,
  });

  final Stream<String> stdoutStream;
  final Stream<String> stderrStream;
  final String command;

  static const routeSettings = RouteSettings(name: '/terminal_outputs/current_command_output');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    /// merge the 2 streams
    final streamController = useMemoized(() => StreamController<List<String>>());
    final _outputs = useRef(<String>[]);
    useEffect(() {
      _outputs.value.add('Running: $command');
      streamController.add(_outputs.value);
      final stdoutSubscription = stdoutStream.listen((event) {
        _outputs.value.add(event);
        streamController.add(_outputs.value);
      });
      final stderrSubscription = stderrStream.listen((event) {
        _outputs.value.add(event);
        streamController.add(_outputs.value);
      });
      return () {
        stdoutSubscription.cancel();
        stderrSubscription.cancel();
        streamController.close();
      };
    }, []);
    final outputs = useStream(streamController.stream);

    Widget content;
    if (outputs.hasData) {
      content = Text(outputs.data!.join('\n'));
    } else if (outputs.hasError) {
      content = Text(outputs.error.toString());
    } else {
      content = const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: AlertDialog(
          scrollable: true,
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
