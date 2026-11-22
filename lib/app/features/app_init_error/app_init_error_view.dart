import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../app.dart';
import '../../design/design.dart';
import '../../shared/widgets/widgets.dart';
import '../../utils/utils.dart';
import '../errors/errors.dart';

/// Startup failed (most often: adb not found). Explains it and offers Try again.
class AppInitErrorView extends StatelessWidget {
  const AppInitErrorView({super.key, required this.exception});
  final AppInitializationException exception;

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      builder: (context, themeMode, light, dark, builder) => MaterialApp(
        title: appName,
        debugShowCheckedModeBanner: false,
        navigatorKey: NavigatorService.instance.navigatorKey(false),
        themeMode: themeMode,
        darkTheme: dark,
        theme: light,
        builder: builder,
        home: _AppInitErrorView(exception: exception),
      ),
    );
  }
}

class _AppInitErrorView extends StatefulWidget {
  const _AppInitErrorView({required this.exception});
  final AppInitializationException exception;

  @override
  State<_AppInitErrorView> createState() => _AppInitErrorViewState();
}

class _AppInitErrorViewState extends State<_AppInitErrorView> {
  bool _retrying = false;

  Future<void> _openLogs() async {
    final dir = await getApplicationSupportDirectory();
    final opener = Platform.isMacOS ? 'open' : (Platform.isWindows ? 'explorer' : 'xdg-open');
    await Process.run(opener, [dir.absolute.path]);
  }

  @override
  Widget build(BuildContext context) {
    final error = ErrorCatalogue.explain(widget.exception.exception);
    final t = AppTokens.of(context);
    final text = Theme.of(context).textTheme;
    final compact = WindowSize.of(context).isCompact;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 20 : 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 28),
                      const SizedBox(width: 10),
                      Text("ADB UI couldn't start", style: text.titleMedium!.copyWith(color: t.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(error.title, style: compact ? text.headlineMedium : text.displaySmall),
                  const SizedBox(height: 16),
                  ErrorExplanation(error: error, showTitle: false),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        autofocus: true,
                        onPressed: _retrying
                            ? null
                            : () {
                                setState(() => _retrying = true);
                                App.run();
                              },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text(_retrying ? 'Trying again…' : 'Try again'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => Clipboard.setData(
                          ClipboardData(text: '${error.title}\n\n${error.details ?? error.message}'),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy details'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _openLogs,
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Open logs folder'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
