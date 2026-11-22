// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'command_queue_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CommandModelLocalStorage _$CommandModelLocalStorageFromJson(
  Map<String, dynamic> json,
) => _CommandModelLocalStorage(
  id: json['id'] as String,
  command: json['command'] as String,
  device: json['device'] == null
      ? null
      : AdbDevice.fromJson(json['device'] as Map<String, dynamic>),
  rawCommand: json['rawCommand'] as String,
  arguments: (json['arguments'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  startedAt: const DateTimeJsonConverter().fromJson(
    json['startedAt'] as String,
  ),
  endedAt: const DateTimeJsonConverter().fromJson(json['endedAt'] as String),
  output: json['output'] as String?,
  error: json['error'] as String?,
);

Map<String, dynamic> _$CommandModelLocalStorageToJson(
  _CommandModelLocalStorage instance,
) => <String, dynamic>{
  'id': instance.id,
  'command': instance.command,
  'device': instance.device,
  'rawCommand': instance.rawCommand,
  'arguments': instance.arguments,
  'startedAt': const DateTimeJsonConverter().toJson(instance.startedAt),
  'endedAt': const DateTimeJsonConverter().toJson(instance.endedAt),
  'output': instance.output,
  'error': instance.error,
};
