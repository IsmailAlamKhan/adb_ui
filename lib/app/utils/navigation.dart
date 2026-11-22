// 🐦 Flutter imports:
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../design/design.dart';
import '../features/errors/errors.dart';
import '../shared/shared.dart';
import 'utils.dart';

/// VERY IMPORTANT NOTE:
/// !!!Use this class when there is no way to get the BuildContext else try to avoid this class as much as possible.!!!
class NavigatorService {
  static final instance = NavigatorService._();
  NavigatorService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  static void init({GlobalKey<NavigatorState>? key}) {
    instance._navigatorKey = key ?? GlobalKey<NavigatorState>();
  }

  GlobalKey<NavigatorState> navigatorKey([bool showWarning = true]) {
    assert(
      _navigatorKey != null,
      'NavigatorService.navigatorKey() called before NavigatorService.init()',
    );
    if (showWarning) {
      logWarning(
        "if you have access to BuildContext which is a decendent of the Navigator please don't use NavigatorService at all",
      );
    }
    return _navigatorKey!;
  }

  NavigatorState navigator([bool showWarning = true]) => navigatorKey(showWarning).currentState!;
  BuildContext context([bool showWarning = true]) => navigatorKey(showWarning).currentContext!;

  Future<T?> pushWithoutContext<T extends Object?>(WidgetBuilder page,
          [bool showWarning = false]) =>
      navigator(showWarning).pushBuilder<T>(page);

  Future<T?> pushAndRemoveUntilWithoutContext<T extends Object?>(
    WidgetBuilder page, [
    RoutePredicate? predicate,
    bool showWarning = false,
  ]) =>
      navigator(showWarning).pushAndRemoveUntilBuilder<T>(page, predicate);
}

mixin NavigationController {
  EventBus get eventBus;

  Future<T?> _push<T>(
    WidgetBuilder page, {
    RoutePredicate? predicate,
    RouteSettings? settings,
  }) {
    final completer = Completer<T?>();
    eventBus.emit(NavigationEvent<T>.push(
      completer: completer,
      page,
      predicate: predicate,
      routeSettings: settings,
    ));
    return completer.future;
  }

  Future<T?> adaptivePush<T>(
    WidgetBuilder page, {
    RoutePredicate? predicate,
    RouteSettings? settings,
  }) {
    final completer = Completer<T?>();
    eventBus.emit(NavigationEvent<T>.adaptivePush(
      completer: completer,
      page,
      routeSettings: settings,
    ));
    return completer.future;
  }

  Future<T?> push<T>(WidgetBuilder builder, {RouteSettings? settings}) =>
      _push<T>(builder, settings: settings);

  Future<T?> pushAndRemoveAll<T>(
    WidgetBuilder builder, {
    RouteSettings? settings,
  }) =>
      _push<T>(builder, predicate: (_) => false, settings: settings);

  Future<T?> pushAndRemoveUntil<T>(
    WidgetBuilder builder,
    RoutePredicate predicate, {
    RouteSettings? settings,
  }) =>
      _push<T>(builder, predicate: predicate, settings: settings);

  Future<T?> pushReplacement<T>(WidgetBuilder builder, {RouteSettings? settings}) {
    final completer = Completer<T?>();
    eventBus.emit(NavigationEvent<T>.pushReplacement(
      builder,
      completer: completer,
      routeSettings: settings,
    ));
    return completer.future;
  }

  Future<T?> pushNamed<T>(String name, {RoutePredicate? predicate, Object? arguments}) {
    final completer = Completer<T?>();
    eventBus.emit(NavigationEvent<T>.pushNamed(
      name,
      arguments: arguments,
      completer: completer,
      predicate: predicate,
    ));
    return completer.future;
  }

  Future<T?> pushNamedReplacement<T>(String name, {Object? arguments}) {
    final completer = Completer<T?>();
    eventBus.emit(NavigationEvent<T>.pushReplacementNamed(
      name,
      arguments: arguments,
      completer: completer,
    ));
    return completer.future;
  }

  void pop<T>([T? result]) => eventBus.emit(NavigationEvent<T>.pop(result: result));
  void popUntil<T>(RoutePredicate predicate) =>
      eventBus.emit(NavigationEvent<T>.popUntil(predicate));

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
    final completer = Completer<T?>();
    eventBus.emit(NavigationEvent<T>.dialog(
      completer: completer,
      pageBuilder: pageBuilder,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      transitionBuilder: transitionBuilder,
      useRootNavigator: useRootNavigator,
      routeSettings: routeSettings,
    ));
    return completer.future;
  }

  void showCustomSnackbar(AppSnackbar snackBar) => eventBus.emit(
        NavigationEvent.snackBar(snackBar),
      );

  void showSnackbar({required String text}) =>
      showToast(tone: ToastTone.info, title: text);

  /// Toast through the snackbar channel. Errors stay longer than successes.
  void showToast({
    required ToastTone tone,
    required String title,
    String? message,
    List<(String, VoidCallback)> actions = const [],
    Duration? duration,
  }) =>
      showCustomSnackbar(AppSnackbar(
        width: 420,
        padding: EdgeInsets.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration ??
            (tone == ToastTone.error ? const Duration(seconds: 8) : const Duration(seconds: 3)),
        content: Builder(
          builder: (context) => AppToast(
            tone: tone,
            title: title,
            message: message,
            actions: actions,
            onDismiss: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      ));

  void showSuccess(String title, {String? message, List<(String, VoidCallback)> actions = const []}) =>
      showToast(tone: ToastTone.success, title: title, message: message, actions: actions);

  /// Shows an error toast. [error] may be an [AppError] or anything [ErrorCatalogue] explains.
  /// Details opens [onDetails] if given, else an [ErrorDetailsDialog].
  void showError(Object error, {VoidCallback? onRetry, VoidCallback? onDetails, String? output}) {
    final explained = error is AppError ? error : ErrorCatalogue.explain(error, output: output);
    showToast(
      tone: ToastTone.error,
      title: explained.title,
      message: explained.hint ?? explained.message,
      actions: [
        if (explained.details != null || explained.steps.length > 1)
          (
            'Details',
            onDetails ??
                () => showDialog<void>(
                      pageBuilder: (_) => ErrorDetailsDialog(error: explained, onRetry: onRetry),
                    ),
          ),
        if (onRetry != null && explained.retryable) ('Retry', onRetry),
      ],
    );
  }

  void showLoading() => eventBus.emit(const NavigationEvent.showLoading());
  void hideLoading() => eventBus.emit(const NavigationEvent.hideLoading());

  void insertOverlay(OverlayEntry entry) => eventBus.emit(NavigationEvent.overlay(entry));

  void showAlert(Alert alert) => alert.showWith(
        hide: () => Alert.hideWith(popUntil),
        show: (builder, settings, timer) => showDialog(
          pageBuilder: builder,
          routeSettings: settings,
        ),
      );

  Future<bool?> confirmDialog(
    String Function(BuildContext context) text, {
    String? confirmText,
    String? cancelText,
    String? title,
    Color? confirmTextColor,
    Color? cancelTextColor,
    List<ConfirmDialogAction>? extraActions,
    ConfirmDialogLayoutBuilder? layoutBuilder,
  }) =>
      showDialog<bool>(
        pageBuilder: (_) => ConfirmDialog(
          text: text,
          confirmText: confirmText,
          cancelText: cancelText,
          title: title,
          confirmTextColor: confirmTextColor,
          cancelTextColor: cancelTextColor,
          extraActions: extraActions,
          layoutBuilder: layoutBuilder,
          onCancel: () => pop(false),
          onConfirm: () => pop(true),
        ),
      );

  Future<T?> modalBottomSheet<T>({
    required WidgetBuilder builder,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
  }) {
    final completer = Completer<T?>();
    eventBus.emit(
      NavigationEvent<T>.bottomSheet(
        completer: completer,
        builder: builder,
        backgroundColor: backgroundColor,
        elevation: elevation,
        shape: shape,
        clipBehavior: clipBehavior,
        constraints: constraints,
        barrierColor: barrierColor,
        isScrollControlled: isScrollControlled,
        useRootNavigator: useRootNavigator,
        isDismissible: isDismissible,
        enableDrag: enableDrag,
        transitionAnimationController: transitionAnimationController,
        routeSettings: routeSettings,
      ),
    );
    return completer.future;
  }

  Future<void> runAsync({
    required Future<void> Function() action,
    required String methodName,
    bool showLoading = true,
  }) async {
    if (showLoading) {
      this.showLoading();
    }
    try {
      await action();
      if (showLoading) {
        hideLoading();
      }
    } catch (e, s) {
      if (e is! AppException) {
        logError('Error while executing $runtimeType.$methodName', error: e, stackTrace: s);
      }
      if (showLoading) {
        hideLoading();
      }
      showError(e);
    }
  }
}

final globalNavigatorControllerProvider = Provider(GlobalNavigatorController.new);

class GlobalNavigatorController with NavigationController {
  @override
  final EventBus eventBus;

  GlobalNavigatorController(Ref ref) : eventBus = ref.read(eventBusProvider);
}
