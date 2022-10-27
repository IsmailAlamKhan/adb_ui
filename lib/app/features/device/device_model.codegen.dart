import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_model.codegen.freezed.dart';
part 'device_model.codegen.g.dart';

@freezed
class Device with _$Device {
  const Device._();
  const factory Device({
    @JsonKey(name: 'device') required String name,
    @JsonKey(name: 'deviceId') required String id,
    @JsonKey(name: 'manufacturer') String? manufacturer,
    @JsonKey(name: 'model') String? model,
    @JsonKey(name: 'product') String? product,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  factory Device.fromJsonNotify(Map<String, dynamic> map) {
    return Device(
      name: map['r_device'],
      id: map['deviceId'] ?? '',
      manufacturer: map['manufacturer'] ?? '',
      model: map['model'] ?? '',
      product: map['product'] ?? '',
    );
  }
}
