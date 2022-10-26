import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';

final networkInfoServiceProvider = Provider<NetworkInfoService>(
  (ref) => NetworkInfoServiceImpl(),
);

abstract class NetworkInfoService {
  Future<String> getWifiIp();
}

class NetworkInfoServiceImpl implements NetworkInfoService {
  final networkInfo = NetworkInfo();
  @override
  Future<String> getWifiIp() async {
    final wifiIp = await NetworkInfo().getWifiIP();
    return wifiIp!;
  }
}
