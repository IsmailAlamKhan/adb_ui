import 'package:flutter/foundation.dart';

/// Android log priority. See spec/features/logcat.md.
enum LogLevel {
  verbose('V', 'Verbose'),
  debug('D', 'Debug'),
  info('I', 'Info'),
  warn('W', 'Warning'),
  error('E', 'Error'),
  fatal('F', 'Fatal');

  const LogLevel(this.letter, this.label);
  final String letter;
  final String label;

  static LogLevel? parse(String letter) => switch (letter) {
        'V' => verbose,
        'D' => debug,
        'I' => info,
        'W' => warn,
        'E' => error,
        'F' || 'A' => fatal,
        _ => null,
      };
}

enum CrashMark { none, start, trace }

/// One logcat line in `-v threadtime` format.
@immutable
class LogcatEntry {
  const LogcatEntry({
    required this.seq,
    required this.raw,
    this.time = '',
    this.pid,
    this.tid,
    this.level,
    this.tag = '',
    this.message = '',
    this.crash = CrashMark.none,
    this.isMarker = false,
  });

  /// Increasing number, unique within a session (list keys).
  final int seq;
  final String raw;
  final String time;
  final int? pid;
  final int? tid;
  final LogLevel? level;
  final String tag;
  final String message;
  final CrashMark crash;

  /// Inserted by the app (e.g. "Process restarted"), not from the device.
  final bool isMarker;

  bool get parsed => level != null;

  LogcatEntry withCrash(CrashMark mark) => LogcatEntry(
        seq: seq,
        raw: raw,
        time: time,
        pid: pid,
        tid: tid,
        level: level,
        tag: tag,
        message: message,
        crash: mark,
        isMarker: isMarker,
      );

  /// First line of a crash: fatal level, Java crash, ANR or native tombstone.
  bool get looksLikeCrashStart =>
      level == LogLevel.fatal ||
      (tag == 'AndroidRuntime' && message.startsWith('FATAL EXCEPTION')) ||
      (tag == 'ActivityManager' && message.startsWith('ANR in')) ||
      (tag == 'DEBUG' && message.contains('*** *** ***'));

  static final _threadtime = RegExp(
    r'^(\d\d-\d\d\s+\d\d:\d\d:\d\d\.\d+)\s+(\d+)\s+(\d+)\s+([VDIWEFA])\s+(.*?)\s*:(?: (.*)|\s*)$',
  );

  /// Parses one line; lines that don't match are kept with only [raw]/[message].
  static LogcatEntry parse(String line, int seq) {
    final m = _threadtime.firstMatch(line);
    if (m == null) return LogcatEntry(seq: seq, raw: line, message: line);
    return LogcatEntry(
      seq: seq,
      raw: line,
      time: m.group(1)!.replaceAll(RegExp(r'\s+'), ' '),
      pid: int.tryParse(m.group(2)!),
      tid: int.tryParse(m.group(3)!),
      level: LogLevel.parse(m.group(4)!),
      tag: m.group(5)!.trim(),
      message: m.group(6) ?? '',
    );
  }
}

enum LogPreset {
  all('All'),
  warnings('Warnings+'),
  errors('Errors+'),
  crashes('Crashes');

  const LogPreset(this.label);
  final String label;
}

/// Filters combine with AND. `aiFields` names the fields the AI filter set (shown with ✨).
@immutable
class LogcatFilter {
  const LogcatFilter({
    this.preset = LogPreset.all,
    this.package,
    this.followForeground = false,
    this.minLevel,
    this.includeTags = const [],
    this.excludeTags = const [],
    this.text = '',
    this.regex = false,
    this.aiExplanation,
    this.aiFields = const {},
  });

  final LogPreset preset;
  final String? package;
  final bool followForeground;
  final LogLevel? minLevel;
  final List<String> includeTags;
  final List<String> excludeTags;
  final String text;
  final bool regex;
  final String? aiExplanation;
  final Set<String> aiFields;

  bool get isEmpty =>
      preset == LogPreset.all &&
      package == null &&
      !followForeground &&
      minLevel == null &&
      includeTags.isEmpty &&
      excludeTags.isEmpty &&
      text.isEmpty;

  LogcatFilter copyWith({
    LogPreset? preset,
    String? package,
    bool clearPackage = false,
    bool? followForeground,
    LogLevel? minLevel,
    bool clearMinLevel = false,
    List<String>? includeTags,
    List<String>? excludeTags,
    String? text,
    bool? regex,
    String? aiExplanation,
    bool clearAi = false,
    Set<String>? aiFields,
  }) =>
      LogcatFilter(
        preset: preset ?? this.preset,
        package: clearPackage ? null : (package ?? this.package),
        followForeground: followForeground ?? this.followForeground,
        minLevel: clearMinLevel ? null : (minLevel ?? this.minLevel),
        includeTags: includeTags ?? this.includeTags,
        excludeTags: excludeTags ?? this.excludeTags,
        text: text ?? this.text,
        regex: regex ?? this.regex,
        aiExplanation: clearAi ? null : (aiExplanation ?? this.aiExplanation),
        aiFields: clearAi ? const {} : (aiFields ?? this.aiFields),
      );

  /// Compiled text matcher, or null when there is no text filter. Invalid regex → literal.
  Pattern? get textPattern {
    if (text.isEmpty) return null;
    if (regex) {
      try {
        return RegExp(text, caseSensitive: false);
      } on FormatException {
        return text.toLowerCase();
      }
    }
    return text.toLowerCase();
  }

  /// Whether [e] passes. [pids] is the followed app's pid set (null = not following).
  bool matches(LogcatEntry e, {Set<int>? pids, Pattern? pattern}) {
    if (e.isMarker) return true;
    if (pids != null && (e.pid == null || !pids.contains(e.pid))) return false;
    final level = e.level;
    switch (preset) {
      case LogPreset.all:
        break;
      case LogPreset.warnings:
        if (level == null || level.index < LogLevel.warn.index) return false;
      case LogPreset.errors:
        if (level == null || level.index < LogLevel.error.index) return false;
      case LogPreset.crashes:
        if (e.crash == CrashMark.none) return false;
    }
    if (minLevel != null && (level == null || level.index < minLevel!.index)) return false;
    if (includeTags.isNotEmpty && !includeTags.contains(e.tag)) return false;
    if (excludeTags.contains(e.tag)) return false;
    final p = pattern ?? textPattern;
    if (p != null) {
      if (p is RegExp) {
        if (!p.hasMatch(e.message) && !p.hasMatch(e.tag)) return false;
      } else {
        final needle = p as String;
        if (!e.message.toLowerCase().contains(needle) && !e.tag.toLowerCase().contains(needle)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is LogcatFilter &&
      other.preset == preset &&
      other.package == package &&
      other.followForeground == followForeground &&
      other.minLevel == minLevel &&
      listEquals(other.includeTags, includeTags) &&
      listEquals(other.excludeTags, excludeTags) &&
      other.text == text &&
      other.regex == regex &&
      other.aiExplanation == aiExplanation &&
      setEquals(other.aiFields, aiFields);

  @override
  int get hashCode => Object.hash(preset, package, followForeground, minLevel,
      Object.hashAll(includeTags), Object.hashAll(excludeTags), text, regex, aiExplanation);
}

/// Marks crash lines and the stack-trace lines that follow them (same pid, up to [traceLines]).
class CrashTracker {
  CrashTracker({this.traceLines = 40});
  final int traceLines;
  final _remaining = <int, int>{};

  LogcatEntry mark(LogcatEntry e) {
    final pid = e.pid;
    if (e.looksLikeCrashStart) {
      if (pid != null) _remaining[pid] = traceLines;
      return e.withCrash(CrashMark.start);
    }
    if (pid != null) {
      final left = _remaining[pid];
      if (left != null && left > 0 && (e.level == LogLevel.error || e.level == LogLevel.fatal)) {
        _remaining[pid] = left - 1;
        return e.withCrash(CrashMark.trace);
      }
      if (left != null && (left <= 0 || e.level != LogLevel.error)) _remaining.remove(pid);
    }
    return e;
  }
}

/// Package in `topResumedActivity` / `mResumedActivity` lines of `dumpsys activity activities`.
String? parseForegroundPackage(String dumpsys) {
  final m = RegExp(r'(?:topResumedActivity|mResumedActivity|ResumedActivity)[:=]?\s*ActivityRecord\{[^}]*?\s([\w.]+)/')
      .firstMatch(dumpsys);
  return m?.group(1);
}

/// Pids from `pidof` output.
Set<int> parsePids(String output) =>
    output.trim().split(RegExp(r'\s+')).map(int.tryParse).whereType<int>().toSet();
