import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../design/app_style.dart';
import '../../shared/services/services.dart';

part 'settings_model.freezed.dart';
part 'settings_model.g.dart';

@freezed
abstract class SettingsModel with _$SettingsModel, LocalStorageModel {
  const SettingsModel._();
  const factory SettingsModel({
    @ThemeModeJsonConverter() required ThemeMode themeMode,

    /// Chosen layout; null until the first-run style picker is completed.
    @AppStyleJsonConverter() AppStyle? style,
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

/// Stores [AppStyle] by name. Missing or unknown values read as null (shows the picker).
class AppStyleJsonConverter extends JsonConverter<AppStyle?, String?> {
  const AppStyleJsonConverter();
  @override
  AppStyle? fromJson(String? json) => AppStyle.tryParse(json);

  @override
  String? toJson(AppStyle? object) => object?.name;
}
