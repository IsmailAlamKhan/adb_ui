enum PremiumFeature {
  logcatStudio,
  intentBuilder,
  fileExplorer,
  macroRecorder,
  performanceDashboard,
  wirelessManager,
}

extension PremiumFeatureLabel on PremiumFeature {
  String get label {
    switch (this) {
      case PremiumFeature.logcatStudio:
        return 'Advanced Logcat Studio';
      case PremiumFeature.intentBuilder:
        return 'Intent & Deep Link Builder';
      case PremiumFeature.fileExplorer:
        return 'Enhanced File Explorer';
      case PremiumFeature.macroRecorder:
        return 'Macro & Automation Recorder';
      case PremiumFeature.performanceDashboard:
        return 'Performance & Network Dashboard';
      case PremiumFeature.wirelessManager:
        return 'Wireless ADB Manager';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.logcatStudio:
        return 'Advanced log filtering, crash detection, regex search, and per-device streaming.';
      case PremiumFeature.intentBuilder:
        return 'Build and fire Android intents and deep links with a visual form.';
      case PremiumFeature.fileExplorer:
        return 'Dual-pane layout, drag & drop, multi-select, SQLite viewer, and SharedPrefs editor.';
      case PremiumFeature.macroRecorder:
        return 'Record, edit, and replay sequences of ADB actions for automation.';
      case PremiumFeature.performanceDashboard:
        return 'Live CPU, memory, and battery charts with network throttling controls.';
      case PremiumFeature.wirelessManager:
        return 'Auto-discover, auto-reconnect, and manage wireless ADB devices.';
    }
  }
}
