import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../shared/shared.dart';
import '../../utils/utils.dart';
import '../logcat/logcat_model.dart';
import 'ai_filter_mapper.dart';

/// Models the AI filter can use (spec/features/ai-log-filter.md).
enum AiModelChoice {
  fast(
    'Fast',
    'Qwen2.5 0.5B · 491 MB',
    'hf://Qwen/Qwen2.5-0.5B-Instruct-GGUF/qwen2.5-0.5b-instruct-q4_k_m.gguf',
    491400032,
  ),
  accurate(
    'Accurate',
    'Qwen2.5 1.5B · 1.1 GB',
    'hf://Qwen/Qwen2.5-1.5B-Instruct-GGUF/qwen2.5-1.5b-instruct-q4_k_m.gguf',
    1117320736,
  );

  const AiModelChoice(this.label, this.detail, this.source, this.bytes);
  final String label;
  final String detail;
  final String source;
  final int bytes;

  ModelSource get modelSource => ModelSource.parse(source);

  static AiModelChoice parse(String? name) =>
      AiModelChoice.values.firstWhere((c) => c.name == name, orElse: () => AiModelChoice.accurate);
}

enum AiModelStatus { unknown, notDownloaded, downloading, ready, loading, loaded, failed }

@immutable
class AiState {
  const AiState({
    this.choice = AiModelChoice.accurate,
    this.status = AiModelStatus.unknown,
    this.progress,
    this.error,
    this.thinking = false,
  });
  final AiModelChoice choice;
  final AiModelStatus status;

  /// Download fraction (null = unknown size).
  final double? progress;
  final Object? error;
  final bool thinking;

  bool get downloaded =>
      status == AiModelStatus.ready || status == AiModelStatus.loading || status == AiModelStatus.loaded;

  AiState copyWith({
    AiModelChoice? choice,
    AiModelStatus? status,
    double? progress,
    bool clearProgress = false,
    Object? error,
    bool clearError = false,
    bool? thinking,
  }) =>
      AiState(
        choice: choice ?? this.choice,
        status: status ?? this.status,
        progress: clearProgress ? null : (progress ?? this.progress),
        error: clearError ? null : (error ?? this.error),
        thinking: thinking ?? this.thinking,
      );
}

/// The model could not be downloaded, loaded or gave unusable output.
class AiModelException extends AppException {
  AiModelException(super.message);
}

final aiControllerProvider = StateNotifierProvider<AiController, AiState>(AiController.new);

/// Owns the on-device model: download, load once, turn sentences into log filters.
/// Nothing but the one-time model download uses the network.
class AiController extends StateNotifier<AiState> {
  AiController(this.ref) : super(const AiState()) {
    _init();
  }

  final Ref ref;
  DefaultModelDownloadManager? _manager;
  ModelDownloadCancelToken? _cancel;
  LlamaEngine? _engine;
  AiModelChoice? _engineChoice;
  Future<void>? _loading;

  Future<DefaultModelDownloadManager> _downloads() async {
    if (_manager != null) return _manager!;
    final dir = await getApplicationSupportDirectory();
    return _manager = DefaultModelDownloadManager(defaultCacheDirectory: p.join(dir.path, 'models'));
  }

  Future<void> _init() async {
    final storage = ref.read(localStorageProvider);
    final saved = await storage.get<String>(LocalStorageKeys.aiModel, defaultValue: '');
    state = state.copyWith(choice: AiModelChoice.parse(saved));
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    try {
      final entry = await (await _downloads()).get(state.choice.modelSource.cacheKey);
      if (!mounted) return;
      if (state.status == AiModelStatus.downloading) return;
      state = state.copyWith(
        status: entry == null ? AiModelStatus.notDownloaded : (_engineChoice == state.choice ? AiModelStatus.loaded : AiModelStatus.ready),
        clearProgress: true,
      );
    } catch (e) {
      if (mounted) state = state.copyWith(status: AiModelStatus.notDownloaded);
    }
  }

  Future<void> setChoice(AiModelChoice choice) async {
    if (choice == state.choice) return;
    await ref.read(localStorageProvider).set<String>(LocalStorageKeys.aiModel, choice.name);
    await _disposeEngine();
    state = state.copyWith(choice: choice, status: AiModelStatus.unknown, clearError: true);
    await refreshStatus();
  }

  Future<void> download() async {
    if (state.status == AiModelStatus.downloading) return;
    final token = _cancel = ModelDownloadCancelToken();
    state = state.copyWith(status: AiModelStatus.downloading, progress: 0, clearError: true);
    try {
      await (await _downloads()).ensureModel(
        state.choice.modelSource,
        options: ModelLoadOptions(cancelToken: token),
        onProgress: (progress) {
          if (mounted) state = state.copyWith(progress: progress.fraction);
        },
      );
      if (mounted) state = state.copyWith(status: AiModelStatus.ready, clearProgress: true);
    } catch (e, s) {
      if (!mounted) return;
      if (token.isCancelled) {
        state = state.copyWith(status: AiModelStatus.notDownloaded, clearProgress: true);
      } else {
        LogFile.instance.dispath('AI model download failed', error: e, stackTrace: s);
        state = state.copyWith(status: AiModelStatus.failed, error: e, clearProgress: true);
      }
    }
  }

  void cancelDownload() => _cancel?.cancel();

  Future<void> deleteModel() async {
    await _disposeEngine();
    await (await _downloads()).remove(state.choice.modelSource.cacheKey);
    state = state.copyWith(status: AiModelStatus.notDownloaded, clearError: true);
  }

  Future<LlamaEngine> _ensureEngine() async {
    if (_engine != null && _engineChoice == state.choice) return _engine!;
    if (_loading != null) {
      await _loading;
      if (_engine != null) return _engine!;
    }
    final completer = Completer<void>();
    _loading = completer.future;
    state = state.copyWith(status: AiModelStatus.loading);
    try {
      final entry = await (await _downloads()).get(state.choice.modelSource.cacheKey);
      if (entry == null) throw AiModelException('The AI model is not downloaded yet.');
      _engine = await LlamaEngine.load(
        LlamaModel(ModelSource.path(entry.filePath)),
        params: const ModelParams(contextSize: 4096),
      );
      _engineChoice = state.choice;
      state = state.copyWith(status: AiModelStatus.loaded);
      return _engine!;
    } catch (e) {
      state = state.copyWith(status: AiModelStatus.failed, error: e);
      rethrow;
    } finally {
      completer.complete();
      _loading = null;
    }
  }

  /// Turns [request] into a filter. Only the sentence and package names reach the model.
  Future<LogcatFilter> filterFor(
    String request, {
    required List<String> packages,
    LogcatFilter current = const LogcatFilter(),
  }) async {
    state = state.copyWith(thinking: true, clearError: true);
    try {
      final engine = await _ensureEngine();
      final messages = [
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: AiFilterMapper.systemPrompt(packages: packages, followedPackage: current.package),
        ),
        LlamaChatMessage.fromText(role: LlamaChatRole.user, text: request),
      ];
      final output = LlamaStructuredOutput<Map<String, dynamic>>.jsonSchema(
        schema: AiFilterMapper.schema,
        decoder: (json) => json,
      );
      Map<String, dynamic>? json;
      Object? lastError;
      for (var attempt = 0; attempt < 2 && json == null; attempt++) {
        try {
          json = await engine.createStructuredJson(
            messages,
            output: output,
            params: const GenerationParams(maxTokens: 256, temp: 0.1),
            enableThinking: false,
          );
        } catch (e) {
          lastError = e;
        }
      }
      if (json == null) {
        throw AiModelException("The AI couldn't make a filter from that. ${lastError ?? ''}".trim());
      }
      return AiFilterMapper.toFilter(json, packages: packages, base: current, request: request);
    } finally {
      if (mounted) state = state.copyWith(thinking: false);
    }
  }

  Future<void> _disposeEngine() async {
    final engine = _engine;
    _engine = null;
    _engineChoice = null;
    await engine?.dispose();
  }

  /// Called on app exit so the native model is freed (llamadart lifecycle rule).
  Future<void> shutdown() => _disposeEngine();

  @override
  void dispose() {
    unawaited(_disposeEngine());
    super.dispose();
  }
}
