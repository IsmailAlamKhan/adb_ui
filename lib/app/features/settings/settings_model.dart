import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../shared/services/services.dart';

part 'settings_model.freezed.dart';
part 'settings_model.g.dart';

@freezed
class SettingsModel with _$SettingsModel, LocalStorageModel {
  const factory SettingsModel({
    @ThemeModeJsonConverter() required ThemeMode themeMode,
  }) = _SettingsModel;
  static const initial = SettingsModel(themeMode: ThemeMode.system);
  factory SettingsModel.fromJson(Map<String, dynamic> json) => _$SettingsModelFromJson(json);
}

class ThemeModeJsonConverter extends JsonConverter<ThemeMode, int> {
  const ThemeModeJsonConverter();
  @override
  ThemeMode fromJson(int json) => ThemeMode.values[json];

  @override
  int toJson(ThemeMode object) => object.index;
}
