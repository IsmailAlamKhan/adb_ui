// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adb_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AdbDevice _$AdbDeviceFromJson(Map<String, dynamic> json) => _AdbDevice(
  id: json['id'] as String,
  type: json['type'] as String,
  model: json['model'] as String,
);

Map<String, dynamic> _$AdbDeviceToJson(_AdbDevice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'model': instance.model,
    };
