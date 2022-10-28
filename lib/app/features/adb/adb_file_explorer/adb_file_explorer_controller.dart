import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../utils/event_bus.dart';
import '../../../utils/logger.dart';
import '../../../utils/navigation.dart';
import '../../features.dart';

final adbFileExplorerControllerProvider = ChangeNotifierProvider<AdbFileExplorerController>(
  AdbFileExplorerController.new,
);

class AdbFileExplorerController extends ChangeNotifier with NavigationController {
  @override
  final EventBus eventBus;
  AdbFileExplorerController(Ref ref) : eventBus = ref.read(eventBusProvider);
  late AdbFileExplorerOpenReason openReason;

  void open(AdbFileExplorerOpenReason openReason) {
    this.openReason = openReason;
  }

  final List<String> _history = [];

  List<String> get history => _history;

  String? _currentPath;
  String? get currentPath => _currentPath;

  void goBack() {
    logInfo(_history);
    if (_history.length == 1) {
      _currentPath = null;
      _history.clear();
      notifyListeners();
    } else if (_history.isNotEmpty) {
      _history.removeLast();
      _currentPath = _history.join('/');

      notifyListeners();
    }
  }

  void onTap(AdbFileSystem file) {
    final isFile = file is AdbFile;
    final path = '${_history.join('/')}/${file.name}';

    if (isFile) {
      if (openReason == AdbFileExplorerOpenReason.pickFile) {
        pop(path);
      }
      return;
    }

    _currentPath = '${_history.join('/')}/${file.name}';
    _history.add(file.name);
    notifyListeners();
  }

  void selectPath() {
    if (openReason == AdbFileExplorerOpenReason.pickFolder) {
      pop(_history.join('/'));
    }
  }
}
