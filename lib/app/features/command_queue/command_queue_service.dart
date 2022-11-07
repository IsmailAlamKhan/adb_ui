import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../shared/shared.dart';
import '../features.dart';

final commandQueueServiceProvider =
    Provider<CommandQueueService>(LocalStorageCommandQueueServiceImpl.new);

abstract class CommandQueueService {
  Future<void> saveCommand(CommandModel command);

  Future<void> removeCommand(CommandModel command);

  Future<void> clear();

  Future<List<CommandModel>> getCommands();
}

class LocalStorageCommandQueueServiceImpl implements CommandQueueService {
  final LocalStorage _localStorage;
  LocalStorageCommandQueueServiceImpl(Ref ref) : _localStorage = ref.read(localStorageProvider);

  @override
  Future<void> saveCommand(CommandModel command) async {
    final commands = await getCommands();
    final newCommands = commands.toList();
    newCommands.add(command);
    await _localStorage.set<List<CommandModelLocalStorage>>(
      LocalStorageKeys.commands,
      newCommands.map((e) => e.toLocalStorage()).toList(),
    );
  }

  @override
  Future<void> removeCommand(CommandModel command) async {
    final commands = await getCommands();
    final newCommands = commands.where((c) => c.id != command.id).toList();
    await _localStorage.set<List<CommandModelLocalStorage>>(
      LocalStorageKeys.commands,
      newCommands.map((e) => e.toLocalStorage()).toList(),
    );
  }

  @override
  Future<void> clear() => _localStorage.delete(LocalStorageKeys.commands);

  @override
  Future<List<CommandModel>> getCommands() async {
    final commands = await _localStorage.get<List<CommandModelLocalStorage>>(
      LocalStorageKeys.commands,
      defaultValue: [],
      fromJson: (json) => (json as List)
          .cast<Map<String, dynamic>>()
          .map(CommandModelLocalStorage.fromJson)
          .toList(),
    );
    return commands.map((c) => c.toModel()).toList();
  }
}
