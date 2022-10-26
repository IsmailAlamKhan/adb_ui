import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/utils.dart';

part 'navigation.freezed.dart';

@freezed
class NavigationEvent<T> with _$NavigationEvent<T>, Event {
  const factory NavigationEvent.dialog({
    required Completer<T?> completer,
    required WidgetBuilder pageBuilder,
    @Default(true) bool barrierDismissible,
    @Default('') String? barrierLabel,
    @Default(Color(0x80000000)) Color barrierColor,
    @Default(AppTheme.defaultDuration) Duration transitionDuration,
    RouteTransitionsBuilder? transitionBuilder,
    @Default(false) bool useRootNavigator,
    RouteSettings? routeSettings,
  }) = _Dialog<T>;

  const factory NavigationEvent.push(
    WidgetBuilder builder, {
    required Completer<T?> completer,
    RoutePredicate? predicate,
    RouteSettings? routeSettings,
  }) = _Push<T>;
  const factory NavigationEvent.pushNamed(
    String route, {
    required Completer<T?> completer,
    RoutePredicate? predicate,
    Object? arguments,
  }) = _PushNamed<T>;
  const factory NavigationEvent.pushReplacement(
    WidgetBuilder builder, {
    required Completer<T?> completer,
    RouteSettings? routeSettings,
  }) = _PushReplacement<T>;
  const factory NavigationEvent.pushReplacementNamed(
    String route, {
    required Completer<T?> completer,
    Object? arguments,
  }) = _PushReplacementNamed<T>;

  const factory NavigationEvent.pop({T? result}) = _Pop<T>;
  const factory NavigationEvent.popUntil(RoutePredicate predicate) = _PopUntil<T>;

  const factory NavigationEvent.snackBar(SnackBar snackbar) = _SnackBar<T>;

  const factory NavigationEvent.showLoading() = _ShowLoading<T>;
  const factory NavigationEvent.hideLoading() = _HideLoading<T>;

  const factory NavigationEvent.bottomSheet({
    required WidgetBuilder builder,
    required Completer<T?> completer,
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    Color? barrierColor,
    @Default(false) bool isScrollControlled,
    @Default(false) bool useRootNavigator,
    @Default(true) bool isDismissible,
    @Default(true) bool enableDrag,
    RouteSettings? routeSettings,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
  }) = _BottomSheet<T>;

  const factory NavigationEvent.overlay(OverlayEntry entry) = _Overlay<T>;
}
