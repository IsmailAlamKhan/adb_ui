/// Pre-filled GitHub issues with recent log lines. See
/// spec/features/about-updates-reporting.md "Bug report / feature request".
library;

const issuesNewUrl = 'https://github.com/IsmailAlamKhan/adb_ui/issues/new';

/// GitHub rejects longer new-issue links.
const maxIssueUrlLength = 7000;
const maxExcerptLines = 40;
const _maxLineLength = 300;

/// The useful, safe lines of a log: `Messege:` / `Error:` lines only, home folder → `~`, no
/// PATH or environment lines, each cut to 300 characters. Oldest first.
List<String> logExcerpt(Iterable<String> lines, {String? home}) {
  final out = <String>[];
  for (final raw in lines) {
    var line = raw.trimRight();
    if (!(line.startsWith('Messege:') || line.startsWith('Error:'))) continue;
    if (line.contains('PATH=') || line.toLowerCase().contains('environment variables')) continue;
    if (home != null && home.length > 1) line = line.replaceAll(home, '~');
    if (line.length > _maxLineLength) line = '${line.substring(0, _maxLineLength)}…';
    out.add(line);
  }
  return out;
}

class BugReportInfo {
  const BugReportInfo({
    required this.version,
    required this.os,
    this.style,
    this.adbVersion,
    this.phone,
  });
  final String version;

  /// e.g. `macOS Version 26.1 (Build 25B78)`.
  final String os;
  final String? style;

  /// First line of `adb version`.
  final String? adbVersion;

  /// e.g. `Pixel 10 Pro, Android 17, Wi-Fi`.
  final String? phone;
}

String _bugBody(BugReportInfo info, String zipName, List<String> log) => [
      '**What happened**',
      'What you did, what you expected, and what happened instead.',
      '',
      '**Steps to reproduce**',
      '1. …',
      '2. …',
      '',
      '**Screenshots or the error details**',
      'If ADB UI showed an error, click **Details** and paste or screenshot it.',
      '',
      '**Logs**',
      'Attach `$zipName` here (ADB UI saved it in your Downloads folder).',
      if (log.isNotEmpty) ...[
        '',
        '<details><summary>Recent log lines</summary>',
        '',
        '```',
        ...log,
        '```',
        '</details>',
      ],
      '',
      '**Your setup**',
      '- ADB UI version: ${info.version}',
      if (info.style != null) '- Style: ${info.style}',
      '- Computer OS: ${info.os}',
      '- adb: ${info.adbVersion ?? 'unknown'}',
      '- Phone: ${info.phone ?? '(none selected — add the model and Android version)'}',
    ].join('\n');

String _url(Map<String, String> params) =>
    Uri.parse(issuesNewUrl).replace(queryParameters: params).toString();

/// New bug issue, pre-filled. Drops the oldest log lines until the link fits
/// [maxIssueUrlLength].
String bugIssueUrl(BugReportInfo info, String zipName, List<String> log) {
  var lines = log.length > maxExcerptLines ? log.sublist(log.length - maxExcerptLines) : log;
  while (true) {
    final url = _url({'labels': 'bug', 'title': '', 'body': _bugBody(info, zipName, lines)});
    if (url.length <= maxIssueUrlLength || lines.isEmpty) return url;
    lines = lines.sublist(lines.length > 4 ? 4 : lines.length);
  }
}

/// New feature request, pre-filled with the template's sections and the version.
String featureIssueUrl({required String version, required String os}) => _url({
      'labels': 'enhancement',
      'title': '',
      'body': [
        '**Is your feature request related to a problem? Please describe.**',
        "What's hard or missing today.",
        '',
        "**Describe the solution you'd like**",
        'What you want ADB UI to do.',
        '',
        "**Describe alternatives you've considered**",
        '',
        '**Additional context**',
        '',
        '_ADB UI $version on ${os}_',
      ].join('\n'),
    });
