import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/adb/adb_model.dart';

abstract class PremiumFeatureFactory {
  Widget buildLogcatStudio({required AdbDevice device});

  Widget buildIntentBuilder({required AdbDevice device});

  Widget buildEnhancedFileExplorer({required AdbDevice device});

  Widget buildMacroRecorder();

  Widget buildPerformanceDashboard({required AdbDevice device});

  Widget buildWirelessManager();

  List<Override> get providerOverrides;
}
