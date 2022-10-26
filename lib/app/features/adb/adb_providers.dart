import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../features.dart';

final connectedDevicesProvider = StreamProvider.autoDispose<List<AdbDevice>>(
  (ref) {
    final adb = ref.watch(adbServiceProvider);
    return adb.connectedDevicesStream;
  },
);
