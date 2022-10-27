import 'package:adb_ui/app/utils/utils.dart';
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:validators/validators.dart';

import '../shared/shared.dart';
import 'theme.dart';

extension ExtendedNum on num {
  bool between(num begin, num end) => this >= begin && this < end;
  bool betweenOrEqual(num begin, num end) => this >= begin && this <= end;
}

extension ExtendedString on String {
  int? toInt() {
    if (isEmpty) return null;
    return int.tryParse(this);
  }

  DateTime toDate() => DateTime.parse(this);
  DateTime toLocalDate() => toDate().toLocal();
  bool get isAlphabetic => isAlpha(this);
  T toEnum<T>(List<T> list) {
    return list.firstWhere((d) => d.toString() == this);
  }

  TextPainter textPainter([TextStyle? style]) => TextPainter(
        text: TextSpan(text: this, style: style),
      )
        ..textDirection = TextDirection.ltr
        ..layout();
  double get width => textPainter().width;
  double get height => textPainter().height;

  String get capitalizeFirst => '${this[0].toUpperCase()}${substring(1)}';
  DateTime? get toDateFromFormatedDateString {
    final _list = split('/');
    if (_list.length >= 3) {
      final _date = '${_list[2]}-${_list[0]}-${_list[1]}'.toDate();
      return _date;
    }
  }

  String get codeToCountryEmoji {
    const int flagOffset = 0x1F1E6;
    const int asciiOffset = 0x41;
    final char1 = codeUnitAt(0) - asciiOffset + flagOffset;
    final char2 = codeUnitAt(1) - asciiOffset + flagOffset;
    return String.fromCharCode(char1) + String.fromCharCode(char2);
  }

  String obsecure(int index, [String obsecureChar = '*']) {
    final _prefixLength = substring(0, index).length;
    final _prefix = obsecureChar * _prefixLength;
    final _suffix = substring(index, length);
    return '$_prefix$_suffix';
  }

  String obsecureEmail([String obsecureChar = '*']) => obsecure(indexOf('@'), obsecureChar);

  String obsecurePhone([String obsecureChar = '*']) => obsecure(length - 2, obsecureChar);

  String toLocalDateTimeWithFormat() => toDate().localDateTime();

  String? makeNullIfEmpty() => isEmpty ? null : this;
  String replaceApostrophe() => replaceAll("'", "''");
}

extension CapExtension on String {
  String toUpperCaseFirst() => length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';

  String toUpperCaseFirstForEachWord() =>
      replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.toUpperCaseFirst()).join(' ');
  bool get isImageFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".jpg") ||
        ext.endsWith(".jpeg") ||
        ext.endsWith(".png") ||
        ext.endsWith(".gif") ||
        ext.endsWith(".bmp");
  }

  bool get isGifFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".gif");
  }

  bool get isVideoFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".mp4") ||
        ext.endsWith(".avi") ||
        ext.endsWith(".wmv") ||
        ext.endsWith(".rmvb") ||
        ext.endsWith(".mpg") ||
        ext.endsWith(".mpeg") ||
        ext.endsWith(".3gp");
  }

  bool get isAudioFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".mp4") ||
        ext.endsWith(".avi") ||
        ext.endsWith(".wmv") ||
        ext.endsWith(".rmvb") ||
        ext.endsWith(".mpg") ||
        ext.endsWith(".mpeg") ||
        ext.endsWith(".3gp") ||
        ext.endsWith(".m4a");
  }

  bool get isPDFFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".pdf");
  }

  bool get isTxtFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".txt");
  }

  bool get isHTMLFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".html");
  }

  bool get isDocumentFile {
    final ext = Uri.parse(this).path;
    return ext.endsWith(".doc");
  }

  bool get isTextFile => isTxtFile || isPDFFile || isHTMLFile || isDocumentFile;
}

extension MyDateTime on DateTime {
  String get dateTimeWithTimeZone {
    final _timeZoneOffset = timeZoneOffset.inHours;
    final formattedTimeZoneOffset = intl.NumberFormat('00').format(_timeZoneOffset);
    return "${intl.DateFormat('yyyy-MM-dd HH:mm:ss').format(this)} ${_timeZoneOffset.isNegative ? '-' : '+'}$formattedTimeZoneOffset";
  }
}

extension ExtendedNullableString on String? {
  String? get capitalizeFirst {
    final _this = this;
    if (_this != null) {
      return _this.capitalizeFirst;
    }
  }
}

extension ExtendedButtonType on ButtonStyle {
  ButtonStyle customCopyWith(ButtonStyle buttonStyle) {
    return ButtonStyle(
      textStyle: buttonStyle.textStyle ?? textStyle,
      backgroundColor: buttonStyle.backgroundColor ?? backgroundColor,
      foregroundColor: buttonStyle.foregroundColor ?? foregroundColor,
      overlayColor: buttonStyle.overlayColor ?? overlayColor,
      shadowColor: buttonStyle.shadowColor ?? shadowColor,
      elevation: buttonStyle.elevation ?? elevation,
      padding: buttonStyle.padding ?? padding,
      minimumSize: buttonStyle.minimumSize ?? minimumSize,
      side: buttonStyle.side ?? side,
      shape: buttonStyle.shape ?? shape,
      mouseCursor: buttonStyle.mouseCursor ?? mouseCursor,
      visualDensity: buttonStyle.visualDensity ?? visualDensity,
      tapTargetSize: buttonStyle.tapTargetSize ?? tapTargetSize,
      animationDuration: buttonStyle.animationDuration ?? animationDuration,
      enableFeedback: buttonStyle.enableFeedback ?? enableFeedback,
    );
  }
}

extension LoopList<T> on List<T> {
  T loop(int index) => this[index % length];
  int? maybeIndexOf(T? item) {
    if (item != null) return indexOf(item);
  }
}

extension ExtendedDateTime on DateTime {
  String localDateTime([intl.DateFormat? format]) {
    final dateFormat = format ?? intl.DateFormat.yMMMMEEEEd();
    final utcDate = dateFormat.format(this);
    final localDate = dateFormat.parse(utcDate, true).toLocal();
    return dateFormat.format(localDate);
  }
}

extension ExtendedSliverOverlapInjector on SliverOverlapInjector {
  static SliverOverlapInjector of(BuildContext context) => SliverOverlapInjector(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
          context,
        ),
      );
}

extension ExtendedSliverOverlapAbsorber on SliverOverlapAbsorber {
  static SliverOverlapAbsorber of(BuildContext context, {Widget? sliver}) => SliverOverlapAbsorber(
        handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
          context,
        ),
        sliver: sliver,
      );
}

extension NestedScrollViewExt on NestedScrollView {
  static NestedScrollViewState? of(BuildContext context) =>
      context.findAncestorStateOfType<NestedScrollViewState>();
}

extension MyUri on Uri {
  bool get isImageFileName => path.isImageFile;
  bool get isVideoFileName => path.isVideoFile;
  bool get isAudioFileName => path.isAudioFile;
  bool get isTxtFileName => path.isTextFile;
}

extension ExtendedBuildContext on BuildContext {
  Rect get getRenderObjectBounds {
    final box = findRenderObject() as RenderBox;
    return box.localToGlobal(Offset.zero) & box.size;
  }
}

extension ExtendedAnimationController on AnimationStatus {
  /// The animation is stopped at the end.
  bool get isCompleted => this == AnimationStatus.completed;

  /// The animation is running backwards, from end to beginning.
  bool get isDismissed => this == AnimationStatus.dismissed;

  /// The animation is running from beginning to end.
  bool get forwarding => this == AnimationStatus.forward;

  /// The animation is stopped at the beginning.
  bool get reversing => this == AnimationStatus.reverse;
}

extension MyList<T> on Iterable<T> {
  List<E> indexedMap<E>(E Function(int index, T element) f) => toList()
      .asMap()
      .map(
        (index, value) => MapEntry(index, f(index, value)),
      )
      .values
      .toList();

  List<T> uniqueList([bool Function(T a, T b)? equals]) {
    final list = <T>[];
    for (final item in this) {
      if (list.contains(item)) continue;
      if (equals != null && list.any((element) => equals(element, item))) continue;
      list.add(item);
    }
    return list;
  }

  T? maybeElementAt(int index) {
    if (index < 0 || index >= length) return null;
    return elementAt(index);
  }
}

bool _ifShowTime({
  required int id,
  required int? otherId,
  required DateTime sentAt,
  required DateTime? otherSentAt,
}) {
  if (otherSentAt == null || otherId == null) return true;
  final _difference = sentAt.difference(otherSentAt);
  return id != otherId && _difference.inMinutes > 20;
}

extension ExtendedInt on int {
  bool toBool() => this == 1;
}

extension ExtendedBool on bool {
  int toInt() => this ? 1 : 0;
}

extension MyNavigatorState on NavigatorState {
  Future<T?> pushBuilder<T extends Object?>(
    WidgetBuilder page, [
    RouteSettings? routeSettings,
  ]) =>
      push(MaterialPageRoute<T>(builder: page, settings: routeSettings));
  Future<T?> pushReplacementBuilder<T extends Object?>(
    WidgetBuilder page, [
    RouteSettings? routeSettings,
  ]) =>
      pushReplacement(MaterialPageRoute<T>(builder: page, settings: routeSettings));

  Future<T?> pushAndRemoveUntilBuilder<T extends Object?>(
    WidgetBuilder page, [
    RoutePredicate? predicate,
    RouteSettings? routeSettings,
  ]) =>
      pushAndRemoveUntil<T>(
        MaterialPageRoute<T>(builder: page, settings: routeSettings),
        predicate ?? (_) => false,
      );

  Future<T?> showDialog<T>({
    required WidgetBuilder pageBuilder,
    bool barrierDismissible = true,
    String? barrierLabel = '',
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = AppTheme.defaultDuration,
    RouteTransitionsBuilder? transitionBuilder,
    bool useRootNavigator = false,
    RouteSettings? routeSettings,
  }) {
    assert(!barrierDismissible || barrierLabel != null);
    return push(
      PageRouteBuilder<T>(
        settings: routeSettings,
        pageBuilder: (context, _, __) => pageBuilder(context),
        barrierColor: barrierColor,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        transitionDuration: transitionDuration,
        transitionsBuilder: transitionBuilder?.call ??
            (_, animation, __, child) => FadeScaleTransition(
                  animation: animation,
                  child: child,
                ),
        fullscreenDialog: true,
        opaque: false,
      ),
    );
  }

  /// show dialog if screen bigger than 600
  /// else push page
  Future<T?> adaptivePush<T extends Object?>(
    WidgetBuilder page, [
    RouteSettings? routeSettings,
  ]) {
    if (isTabletSize(context)) {
      return showDialog<T>(pageBuilder: page, routeSettings: routeSettings);
    } else {
      return pushBuilder<T>(page, routeSettings);
    }
  }

  void showLoading() => showDialog(
        pageBuilder: (_) => WillPopScope(
          child: const Center(child: CircularProgressIndicator()),
          onWillPop: () => Future.value(kDebugMode),
        ),
        barrierColor: Colors.black87,
        routeSettings: const RouteSettings(name: 'loading'),
      );
  void hideLoading() => popUntil((route) => route.settings.name != 'loading');
}

extension MyScaffoldMessenger on ScaffoldMessengerState {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showAppSnackbar({
    String? text,
    SnackBar? snackbar,
  }) {
    final localSnackbar = snackbar ?? AppSnackbar.text(text!);
    return showSnackBar(localSnackbar);
  }
}

extension ExtendedButtonStyle on ButtonStyle {
  ButtonStyle filled(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = colors.primary;
    final onPrimary = colors.onPrimary;
    return ElevatedButton.styleFrom(
      foregroundColor: onPrimary,
      backgroundColor: primary,
    ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)).merge(this);
  }
}

extension ExtendedColor on Color {
  String toHex() => '#${value.toRadixString(16).substring(2)}';
}

extension ColorX on Color {
  double _computeLuminance() {
    return computeLuminance();
  }

  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  Brightness brightnessBasedOnBackground() {
    if (_computeLuminance() > 0.5) {
      return Brightness.light;
    } else {
      return Brightness.dark;
    }
  }

  Color? contrastColor({
    Color? Function(Brightness brightness)? colorBuilder,
  }) =>
      brightnessBasedOnBackground().contrastColor(colorBuilder: colorBuilder);
}

extension BrightnessX on Brightness {
  Color? contrastColor({
    Color? Function(Brightness brightness)? colorBuilder,
  }) {
    if (colorBuilder != null) {
      return colorBuilder(this);
    }
    if (this == Brightness.light) {
      return Colors.black87;
    } else {
      return Colors.white70;
    }
  }
}
