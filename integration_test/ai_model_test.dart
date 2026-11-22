// Runs real requests through the on-device model, the same way AiController does, inside a
// real app build (llama.cpp is linked into the app, not into `flutter test`).
// Run: flutter test integration_test/ai_model_test.dart -d macos
// Skipped unless a model has been downloaded by the app (Settings → AI).
import 'dart:io';

import 'package:adb_ui/app/features/ai/ai_filter_mapper.dart';
import 'package:adb_ui/app/features/logcat/logcat_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:llamadart/llamadart.dart';

File? _findModel() {
  final home = Platform.environment['HOME'];
  if (home == null) return null;
  final dir = Directory('$home/Library/Application Support/com.adb-ui/models');
  if (!dir.existsSync()) return null;
  for (final f in dir.listSync(recursive: true)) {
    if (f is File && f.path.endsWith('.gguf')) return f;
  }
  return null;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final model = _findModel();
  const packages = ['com.Slack', 'com.google.android.gm', 'com.example.shop', 'com.whatsapp'];

  test('model turns sentences into filters', () async {
    final engine = await LlamaEngine.load(
      LlamaModel(ModelSource.path(model!.path)),
      params: const ModelParams(contextSize: 4096),
    );
    try {
      Future<LogcatFilter> ask(String request) async {
        final watch = Stopwatch()..start();
        final json = await engine.createStructuredJson(
          [
            LlamaChatMessage.fromText(
              role: LlamaChatRole.system,
              text: AiFilterMapper.systemPrompt(packages: packages),
            ),
            LlamaChatMessage.fromText(role: LlamaChatRole.user, text: request),
          ],
          output: LlamaStructuredOutput<Map<String, dynamic>>.jsonSchema(
            schema: AiFilterMapper.schema,
            decoder: (j) => j,
          ),
          params: const GenerationParams(maxTokens: 256, temp: 0.1),
          enableThinking: false,
        );
        final filter = AiFilterMapper.toFilter(json, packages: packages, request: request);
        // ignore: avoid_print
        print('"$request" → $json\n   applied: preset=${filter.preset.name} package=${filter.package} level=${filter.minLevel?.letter} include=${filter.includeTags} exclude=${filter.excludeTags} text="${filter.text}"  (${watch.elapsedMilliseconds} ms)');
        return filter;
      }

      final slack = await ask('errors from slack');
      expect(slack.package, 'com.Slack');
      expect(slack.preset == LogPreset.errors || slack.minLevel == LogLevel.error, isTrue);

      expect(slack.includeTags, isEmpty);
      expect(slack.text.split(' ').length, lessThanOrEqualTo(3));

      final crashes = await ask('show me crashes');
      expect(crashes.preset, LogPreset.crashes);
      expect(crashes.package, isNull);
      expect(crashes.minLevel, isNull);

      final whatsapp = await ask('network timeouts in whatsapp');
      expect(whatsapp.package, 'com.whatsapp');
      expect(whatsapp.text, 'network|timeout');

      final hide = await ask('hide chatty and Choreographer logs');
      expect(hide.includeTags, isEmpty);
      expect(hide.package, isNull);
    } finally {
      await engine.dispose();
    }
  }, skip: model == null ? 'No AI model downloaded' : false, timeout: const Timeout(Duration(minutes: 5)));
}
