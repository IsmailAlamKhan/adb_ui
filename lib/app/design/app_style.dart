/// The three selectable layouts of the app. See spec/08-redesign.md.
enum AppStyle {
  workbench,
  console,
  launcher;

  String get label => switch (this) {
        AppStyle.workbench => 'Workbench',
        AppStyle.console => 'Console',
        AppStyle.launcher => 'Launcher',
      };

  String get tagline => switch (this) {
        AppStyle.workbench => 'Sidebar of devices. Each device gets tabs for apps, files and shell.',
        AppStyle.console => 'Dense and keyboard-driven, with a docked activity terminal.',
        AppStyle.launcher => 'Big device cards and a command palette for everything.',
      };

  static AppStyle? tryParse(Object? value) {
    for (final style in values) {
      if (style.name == value) return style;
    }
    return null;
  }
}
