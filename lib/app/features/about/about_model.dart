import 'package:freezed_annotation/freezed_annotation.dart';

part 'about_model.freezed.dart';

@freezed
class AboutModel with _$AboutModel {
  const factory AboutModel({
    required bool updateAvailable,
    String? updateAvailableVersion,
  }) = _AboutModel;

  static const AboutModel updateNotAvailable = AboutModel(updateAvailable: false);
}
