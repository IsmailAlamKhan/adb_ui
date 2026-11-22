// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.codegen.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Device _$DeviceFromJson(Map<String, dynamic> json) => _Device(
  name: json['device'] as String,
  id: json['deviceId'] as String,
  manufacturer: json['manufacturer'] as String?,
  model: json['model'] as String?,
  product: json['product'] as String?,
);

Map<String, dynamic> _$DeviceToJson(_Device instance) => <String, dynamic>{
  'device': instance.name,
  'deviceId': instance.id,
  'manufacturer': instance.manufacturer,
  'model': instance.model,
  'product': instance.product,
};
