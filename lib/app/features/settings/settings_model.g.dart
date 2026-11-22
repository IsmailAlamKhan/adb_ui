// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    _SettingsModel(
      themeMode: const ThemeModeJsonConverter().fromJson(
        (json['themeMode'] as num).toInt(),
      ),
      style: const AppStyleJsonConverter().fromJson(json['style'] as String?),
    );

Map<String, dynamic> _$SettingsModelToJson(_SettingsModel instance) =>
    <String, dynamic>{
      'themeMode': const ThemeModeJsonConverter().toJson(instance.themeMode),
      'style': const AppStyleJsonConverter().toJson(instance.style),
    };
