/// Open-source builds use this no-op. Pro builds can replace the import target
/// or invoke [PremiumRegistry.register] from `adb_ui_pro` before [App.run].
void registerProFeatures() {}
