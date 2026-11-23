import '../logcat/logcat_model.dart';

/// Pure parts of the AI log filter: the prompt, the JSON schema and turning the model's JSON
/// into a [LogcatFilter]. No model needed, so it's unit-tested (spec/features/ai-log-filter.md).
class AiFilterMapper {
  const AiFilterMapper._();

  static const schema = <String, dynamic>{
    'type': 'object',
    'properties': {
      'preset': {
        'type': 'string',
        'enum': ['all', 'warnings', 'errors', 'crashes'],
      },
      'package': {'type': 'string'},
      'minLevel': {
        'type': 'string',
        'enum': ['V', 'D', 'I', 'W', 'E', 'F'],
      },
      'includeTags': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'excludeTags': {
        'type': 'array',
        'items': {'type': 'string'},
      },
      'text': {'type': 'string'},
      'regex': {'type': 'boolean'},
      'explanation': {'type': 'string'},
    },
    'required': ['explanation'],
    'additionalProperties': false,
  };

  static String systemPrompt({
    required List<String> packages,
    Map<String, String> labels = const {},
    String? followedPackage,
  }) {
    // Keep the package list short enough for a small context window.
    final shown = packages.take(400).map((p) => labels[p] == null ? p : '$p (${labels[p]})').join(', ');
    return '''
You turn a request about Android logcat into a filter. Reply with JSON only.
Fields (all optional except explanation):
- preset: "all", "warnings" (warning and above), "errors" (error and above) or "crashes" (crashes, ANRs and their stack traces).
- package: the Android package to show logs for. Must be one of the installed packages listed below. Use it when the user names an app ("slack", "my app" = the followed app).
- minLevel: lowest log level to show: V, D, I, W, E or F.
- includeTags: only these logcat tags. excludeTags: hide these tags.
- text: words that must appear in the message. regex: true if text is a regular expression.
- explanation: one short sentence saying what the filter shows.
Leave out fields the request doesn't ask for. Only use words that are in the request.
text is one or two words copied from the request, never a sentence.
Examples:
"errors from slack" -> {"preset":"errors","package":"com.Slack","explanation":"Errors from Slack"}
"show crashes" -> {"preset":"crashes","explanation":"Crashes and their stack traces"}
"network timeouts in gmail" -> {"package":"com.google.android.gm","text":"timeout","explanation":"Gmail lines mentioning timeout"}
"hide chatty logs" -> {"excludeTags":["chatty"],"explanation":"Everything except the chatty tag"}
"warnings and up" -> {"preset":"warnings","explanation":"Warnings, errors and crashes"}
Followed app: ${followedPackage ?? 'none'}.
Installed packages: $shown''';
  }

  /// Turns the model's JSON into a filter. Unknown packages are dropped; unknown values ignored.
  /// Small models invent values, so every field is checked against [request]: text and tags
  /// must appear in it, an app must be named in it (or "my app" = the followed app), and
  /// "hide/without/except" turns mentioned tags into hidden tags.
  static LogcatFilter toFilter(
    Map<String, dynamic> json, {
    required List<String> packages,
    Map<String, String> labels = const {},
    LogcatFilter base = const LogcatFilter(),
    String? request,
  }) {
    final said = request?.toLowerCase();
    bool mentioned(String value) => said == null || said.contains(value.toLowerCase());
    final hiding = said != null && RegExp(r'\b(hide|without|exclude|except|ignore|no)\b').hasMatch(said);
    final fields = <String>{};
    var filter = const LogcatFilter().copyWith(followForeground: base.followForeground);
    // Rules on the request come first; the model only fills what they didn't find.
    Object? rulesText;
    if (request != null) {
      final rules = fromRules(request, packages: packages, labels: labels, followed: base.package);
      rulesText = rules['text'];
      json = {...json, ...rules, if (rules['excludeTags'] != null || json['excludeTags'] != null)
        'excludeTags': {...?(json['excludeTags'] as List?)?.whereType<String>(), ...?(rules['excludeTags'] as List?)?.whereType<String>()}.toList()};
    }

    final preset = switch (json['preset']) {
      'warnings' => LogPreset.warnings,
      'errors' => LogPreset.errors,
      'crashes' => LogPreset.crashes,
      'all' => LogPreset.all,
      _ => null,
    };
    if (preset != null) {
      filter = filter.copyWith(preset: preset);
      if (preset != LogPreset.all) fields.add('preset');
    }

    var package = resolvePackage(json['package'], packages);
    if (package != null && said != null && !_namesApp(said, package, labels[package])) {
      package = RegExp(r'\b(my|this|the) app\b').hasMatch(said) ? base.package : null;
    }
    if (package != null && package != base.package) {
      filter = filter.copyWith(package: package, followForeground: false);
      fields.add('package');
    } else if (base.package != null) {
      filter = filter.copyWith(package: base.package);
    }

    var level = json['minLevel'] is String ? LogLevel.parse(json['minLevel'] as String) : null;
    // A minimum level would hide crash stack traces; presets already imply their level.
    if (preset != null && preset != LogPreset.all) level = null;
    if (level != null) {
      filter = filter.copyWith(minLevel: level);
      fields.add('minLevel');
    }

    List<String> strings(Object? v) =>
        v is List ? v.whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList() : const [];
    var include = strings(json['includeTags']).where(mentioned).toList();
    var exclude = strings(json['excludeTags']).where(mentioned).toList();
    if (hiding && include.isNotEmpty) {
      exclude = {...exclude, ...include}.toList();
      include = [];
    }
    if (include.isNotEmpty) {
      filter = filter.copyWith(includeTags: include);
      fields.add('includeTags');
    }
    if (exclude.isNotEmpty) {
      filter = filter.copyWith(excludeTags: exclude);
      fields.add('excludeTags');
    }

    var text = json['text'] is String ? (json['text'] as String).trim() : '';
    // Model-made text must be a short phrase from the request; rule-made text is trusted.
    if (text != rulesText &&
        (text.split(RegExp(r'\s+')).length > 3 || !mentioned(text.replaceAll(RegExp(r's$'), '')))) {
      text = '';
    }
    if (text.isNotEmpty) {
      var regex = json['regex'] == true;
      if (regex) {
        try {
          RegExp(text);
        } on FormatException {
          regex = false;
        }
      }
      filter = filter.copyWith(text: text, regex: regex);
      fields.add('text');
    }

    final explanation = json['explanation'] is String ? (json['explanation'] as String).trim() : '';
    return filter.copyWith(aiExplanation: explanation.isEmpty ? null : explanation, aiFields: fields);
  }

  static const _stopWords = {
    'the', 'a', 'an', 'and', 'or', 'from', 'in', 'of', 'for', 'to', 'all', 'any', 'logs', 'log',
    'lines', 'messages', 'tag', 'tags', 'me', 'show', 'only', 'just', 'please', 'hide', 'without',
    'exclude', 'except', 'ignore', 'no', 'my', 'this', 'app', 'with',
  };

  /// Deterministic reading of the request: preset words, a named installed app, and tags to
  /// hide. Returned as model-style JSON so it merges with the model's answer.
  static Map<String, dynamic> fromRules(
    String request, {
    required List<String> packages,
    Map<String, String> labels = const {},
    String? followed,
  }) {
    final said = request.toLowerCase();
    final out = <String, dynamic>{};
    if (RegExp(r'\b(crash\w*|anrs?|fatal|exceptions?|tombstones?)\b').hasMatch(said)) {
      out['preset'] = 'crashes';
    } else if (RegExp(r'\b(errors?|failures?|failed|fails?)\b').hasMatch(said)) {
      out['preset'] = 'errors';
    } else if (RegExp(r'\bwarn(ing)?s?\b').hasMatch(said)) {
      out['preset'] = 'warnings';
    }
    final named = packages.where((p) => _namesApp(said, p, labels[p])).toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (named.isNotEmpty) {
      out['package'] = named.first;
    } else if (followed != null && RegExp(r'\b(my|this|the) app\b').hasMatch(said)) {
      out['package'] = followed;
    }
    final hide = RegExp(r'\b(?:hide|without|exclude|except|ignore|no)\b(.*)', caseSensitive: false).firstMatch(request);
    // Leftover meaningful words (not preset words, the app's name or hidden tags) are searched for.
    final shown = hide == null ? request : request.substring(0, hide.start);
    final appWords = {
      for (final p in named.take(1)) ...[...p.toLowerCase().split('.'), ...?labels[p]?.toLowerCase().split(RegExp(r'\s+'))],
    };
    final words = shown
        .toLowerCase()
        .split(RegExp(r'[^\w.-]+'))
        .where((w) => w.length >= 3 && !_stopWords.contains(w) && !appWords.contains(w))
        .where((w) => !RegExp(r'^(crash\w*|anrs?|fatal|exceptions?|tombstones?|errors?|failures?|failed|fails?|warn(ing)?s?|everything|stuff)$').hasMatch(w))
        .map((w) => w.length > 4 && w.endsWith('s') ? w.substring(0, w.length - 1) : w)
        .toSet()
        .toList();
    if (words.length == 1) {
      out['text'] = words.first;
    } else if (words.length > 1 && words.length <= 4) {
      out['text'] = words.map(RegExp.escape).join('|');
      out['regex'] = true;
    }
    if (hide != null) {
      final tags = hide
          .group(1)!
          .split(RegExp(r'[\s,]+'))
          .map((w) => w.replaceAll(RegExp(r'[^\w.-]'), ''))
          .where((w) => w.isNotEmpty && !_stopWords.contains(w.toLowerCase()))
          .toList();
      if (tags.isNotEmpty) out['excludeTags'] = tags;
    }
    return out;
  }

  static const _genericSegments = {'com', 'org', 'net', 'android', 'google', 'app', 'apps', 'mobile', 'example'};

  /// Whether [said] names [package]: its app name ([label], as a whole word) or a meaningful
  /// segment of the package appears in the request.
  static bool _namesApp(String said, String package, [String? label]) {
    final name = label?.trim().toLowerCase();
    if (name != null && name.length >= 3 && RegExp('\\b${RegExp.escape(name)}\\b').hasMatch(said)) return true;
    return package
        .toLowerCase()
        .split('.')
        .where((s) => s.length >= 3 && !_genericSegments.contains(s))
        .any(said.contains);
  }

  /// Exact package, or the one whose name or last segment matches case-insensitively.
  static String? resolvePackage(Object? value, List<String> packages) {
    if (value is! String) return null;
    final wanted = value.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    for (final p in packages) {
      if (p.toLowerCase() == wanted) return p;
    }
    for (final p in packages) {
      final last = p.split('.').last.toLowerCase();
      if (last == wanted) return p;
    }
    final matches = packages.where((p) => p.toLowerCase().contains(wanted)).toList();
    return matches.length == 1 ? matches.first : null;
  }
}
