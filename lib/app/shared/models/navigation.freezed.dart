// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'navigation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NavigationEvent<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NavigationEvent<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NavigationEvent<$T>()';
}


}

/// @nodoc
class $NavigationEventCopyWith<T,$Res>  {
$NavigationEventCopyWith(NavigationEvent<T> _, $Res Function(NavigationEvent<T>) __);
}


/// Adds pattern-matching-related methods to [NavigationEvent].
extension NavigationEventPatterns<T> on NavigationEvent<T> {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _Dialog<T> value)?  dialog,TResult Function( _Push<T> value)?  push,TResult Function( _AdaptivePush<T> value)?  adaptivePush,TResult Function( _PushNamed<T> value)?  pushNamed,TResult Function( _PushReplacement<T> value)?  pushReplacement,TResult Function( _PushReplacementNamed<T> value)?  pushReplacementNamed,TResult Function( _Pop<T> value)?  pop,TResult Function( _PopUntil<T> value)?  popUntil,TResult Function( _SnackBar<T> value)?  snackBar,TResult Function( _ShowLoading<T> value)?  showLoading,TResult Function( _HideLoading<T> value)?  hideLoading,TResult Function( _BottomSheet<T> value)?  bottomSheet,TResult Function( _Overlay<T> value)?  overlay,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Dialog() when dialog != null:
return dialog(_that);case _Push() when push != null:
return push(_that);case _AdaptivePush() when adaptivePush != null:
return adaptivePush(_that);case _PushNamed() when pushNamed != null:
return pushNamed(_that);case _PushReplacement() when pushReplacement != null:
return pushReplacement(_that);case _PushReplacementNamed() when pushReplacementNamed != null:
return pushReplacementNamed(_that);case _Pop() when pop != null:
return pop(_that);case _PopUntil() when popUntil != null:
return popUntil(_that);case _SnackBar() when snackBar != null:
return snackBar(_that);case _ShowLoading() when showLoading != null:
return showLoading(_that);case _HideLoading() when hideLoading != null:
return hideLoading(_that);case _BottomSheet() when bottomSheet != null:
return bottomSheet(_that);case _Overlay() when overlay != null:
return overlay(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _Dialog<T> value)  dialog,required TResult Function( _Push<T> value)  push,required TResult Function( _AdaptivePush<T> value)  adaptivePush,required TResult Function( _PushNamed<T> value)  pushNamed,required TResult Function( _PushReplacement<T> value)  pushReplacement,required TResult Function( _PushReplacementNamed<T> value)  pushReplacementNamed,required TResult Function( _Pop<T> value)  pop,required TResult Function( _PopUntil<T> value)  popUntil,required TResult Function( _SnackBar<T> value)  snackBar,required TResult Function( _ShowLoading<T> value)  showLoading,required TResult Function( _HideLoading<T> value)  hideLoading,required TResult Function( _BottomSheet<T> value)  bottomSheet,required TResult Function( _Overlay<T> value)  overlay,}){
final _that = this;
switch (_that) {
case _Dialog():
return dialog(_that);case _Push():
return push(_that);case _AdaptivePush():
return adaptivePush(_that);case _PushNamed():
return pushNamed(_that);case _PushReplacement():
return pushReplacement(_that);case _PushReplacementNamed():
return pushReplacementNamed(_that);case _Pop():
return pop(_that);case _PopUntil():
return popUntil(_that);case _SnackBar():
return snackBar(_that);case _ShowLoading():
return showLoading(_that);case _HideLoading():
return hideLoading(_that);case _BottomSheet():
return bottomSheet(_that);case _Overlay():
return overlay(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _Dialog<T> value)?  dialog,TResult? Function( _Push<T> value)?  push,TResult? Function( _AdaptivePush<T> value)?  adaptivePush,TResult? Function( _PushNamed<T> value)?  pushNamed,TResult? Function( _PushReplacement<T> value)?  pushReplacement,TResult? Function( _PushReplacementNamed<T> value)?  pushReplacementNamed,TResult? Function( _Pop<T> value)?  pop,TResult? Function( _PopUntil<T> value)?  popUntil,TResult? Function( _SnackBar<T> value)?  snackBar,TResult? Function( _ShowLoading<T> value)?  showLoading,TResult? Function( _HideLoading<T> value)?  hideLoading,TResult? Function( _BottomSheet<T> value)?  bottomSheet,TResult? Function( _Overlay<T> value)?  overlay,}){
final _that = this;
switch (_that) {
case _Dialog() when dialog != null:
return dialog(_that);case _Push() when push != null:
return push(_that);case _AdaptivePush() when adaptivePush != null:
return adaptivePush(_that);case _PushNamed() when pushNamed != null:
return pushNamed(_that);case _PushReplacement() when pushReplacement != null:
return pushReplacement(_that);case _PushReplacementNamed() when pushReplacementNamed != null:
return pushReplacementNamed(_that);case _Pop() when pop != null:
return pop(_that);case _PopUntil() when popUntil != null:
return popUntil(_that);case _SnackBar() when snackBar != null:
return snackBar(_that);case _ShowLoading() when showLoading != null:
return showLoading(_that);case _HideLoading() when hideLoading != null:
return hideLoading(_that);case _BottomSheet() when bottomSheet != null:
return bottomSheet(_that);case _Overlay() when overlay != null:
return overlay(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Completer<T?> completer,  WidgetBuilder pageBuilder,  bool barrierDismissible,  String? barrierLabel,  Color barrierColor,  Duration transitionDuration,  RouteTransitionsBuilder? transitionBuilder,  bool useRootNavigator,  RouteSettings? routeSettings)?  dialog,TResult Function( WidgetBuilder builder,  Completer<T?> completer,  RoutePredicate? predicate,  RouteSettings? routeSettings)?  push,TResult Function( WidgetBuilder builder,  Completer<T?> completer,  RouteSettings? routeSettings)?  adaptivePush,TResult Function( String route,  Completer<T?> completer,  RoutePredicate? predicate,  Object? arguments)?  pushNamed,TResult Function( WidgetBuilder builder,  Completer<T?> completer,  RouteSettings? routeSettings)?  pushReplacement,TResult Function( String route,  Completer<T?> completer,  Object? arguments)?  pushReplacementNamed,TResult Function( T? result)?  pop,TResult Function( RoutePredicate predicate)?  popUntil,TResult Function( SnackBar snackbar)?  snackBar,TResult Function()?  showLoading,TResult Function()?  hideLoading,TResult Function( WidgetBuilder builder,  Completer<T?> completer,  Color? backgroundColor,  double? elevation,  ShapeBorder? shape,  Clip? clipBehavior,  BoxConstraints? constraints,  Color? barrierColor,  bool isScrollControlled,  bool useRootNavigator,  bool isDismissible,  bool enableDrag,  RouteSettings? routeSettings,  AnimationController? transitionAnimationController,  Offset? anchorPoint)?  bottomSheet,TResult Function( OverlayEntry entry)?  overlay,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Dialog() when dialog != null:
return dialog(_that.completer,_that.pageBuilder,_that.barrierDismissible,_that.barrierLabel,_that.barrierColor,_that.transitionDuration,_that.transitionBuilder,_that.useRootNavigator,_that.routeSettings);case _Push() when push != null:
return push(_that.builder,_that.completer,_that.predicate,_that.routeSettings);case _AdaptivePush() when adaptivePush != null:
return adaptivePush(_that.builder,_that.completer,_that.routeSettings);case _PushNamed() when pushNamed != null:
return pushNamed(_that.route,_that.completer,_that.predicate,_that.arguments);case _PushReplacement() when pushReplacement != null:
return pushReplacement(_that.builder,_that.completer,_that.routeSettings);case _PushReplacementNamed() when pushReplacementNamed != null:
return pushReplacementNamed(_that.route,_that.completer,_that.arguments);case _Pop() when pop != null:
return pop(_that.result);case _PopUntil() when popUntil != null:
return popUntil(_that.predicate);case _SnackBar() when snackBar != null:
return snackBar(_that.snackbar);case _ShowLoading() when showLoading != null:
return showLoading();case _HideLoading() when hideLoading != null:
return hideLoading();case _BottomSheet() when bottomSheet != null:
return bottomSheet(_that.builder,_that.completer,_that.backgroundColor,_that.elevation,_that.shape,_that.clipBehavior,_that.constraints,_that.barrierColor,_that.isScrollControlled,_that.useRootNavigator,_that.isDismissible,_that.enableDrag,_that.routeSettings,_that.transitionAnimationController,_that.anchorPoint);case _Overlay() when overlay != null:
return overlay(_that.entry);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Completer<T?> completer,  WidgetBuilder pageBuilder,  bool barrierDismissible,  String? barrierLabel,  Color barrierColor,  Duration transitionDuration,  RouteTransitionsBuilder? transitionBuilder,  bool useRootNavigator,  RouteSettings? routeSettings)  dialog,required TResult Function( WidgetBuilder builder,  Completer<T?> completer,  RoutePredicate? predicate,  RouteSettings? routeSettings)  push,required TResult Function( WidgetBuilder builder,  Completer<T?> completer,  RouteSettings? routeSettings)  adaptivePush,required TResult Function( String route,  Completer<T?> completer,  RoutePredicate? predicate,  Object? arguments)  pushNamed,required TResult Function( WidgetBuilder builder,  Completer<T?> completer,  RouteSettings? routeSettings)  pushReplacement,required TResult Function( String route,  Completer<T?> completer,  Object? arguments)  pushReplacementNamed,required TResult Function( T? result)  pop,required TResult Function( RoutePredicate predicate)  popUntil,required TResult Function( SnackBar snackbar)  snackBar,required TResult Function()  showLoading,required TResult Function()  hideLoading,required TResult Function( WidgetBuilder builder,  Completer<T?> completer,  Color? backgroundColor,  double? elevation,  ShapeBorder? shape,  Clip? clipBehavior,  BoxConstraints? constraints,  Color? barrierColor,  bool isScrollControlled,  bool useRootNavigator,  bool isDismissible,  bool enableDrag,  RouteSettings? routeSettings,  AnimationController? transitionAnimationController,  Offset? anchorPoint)  bottomSheet,required TResult Function( OverlayEntry entry)  overlay,}) {final _that = this;
switch (_that) {
case _Dialog():
return dialog(_that.completer,_that.pageBuilder,_that.barrierDismissible,_that.barrierLabel,_that.barrierColor,_that.transitionDuration,_that.transitionBuilder,_that.useRootNavigator,_that.routeSettings);case _Push():
return push(_that.builder,_that.completer,_that.predicate,_that.routeSettings);case _AdaptivePush():
return adaptivePush(_that.builder,_that.completer,_that.routeSettings);case _PushNamed():
return pushNamed(_that.route,_that.completer,_that.predicate,_that.arguments);case _PushReplacement():
return pushReplacement(_that.builder,_that.completer,_that.routeSettings);case _PushReplacementNamed():
return pushReplacementNamed(_that.route,_that.completer,_that.arguments);case _Pop():
return pop(_that.result);case _PopUntil():
return popUntil(_that.predicate);case _SnackBar():
return snackBar(_that.snackbar);case _ShowLoading():
return showLoading();case _HideLoading():
return hideLoading();case _BottomSheet():
return bottomSheet(_that.builder,_that.completer,_that.backgroundColor,_that.elevation,_that.shape,_that.clipBehavior,_that.constraints,_that.barrierColor,_that.isScrollControlled,_that.useRootNavigator,_that.isDismissible,_that.enableDrag,_that.routeSettings,_that.transitionAnimationController,_that.anchorPoint);case _Overlay():
return overlay(_that.entry);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Completer<T?> completer,  WidgetBuilder pageBuilder,  bool barrierDismissible,  String? barrierLabel,  Color barrierColor,  Duration transitionDuration,  RouteTransitionsBuilder? transitionBuilder,  bool useRootNavigator,  RouteSettings? routeSettings)?  dialog,TResult? Function( WidgetBuilder builder,  Completer<T?> completer,  RoutePredicate? predicate,  RouteSettings? routeSettings)?  push,TResult? Function( WidgetBuilder builder,  Completer<T?> completer,  RouteSettings? routeSettings)?  adaptivePush,TResult? Function( String route,  Completer<T?> completer,  RoutePredicate? predicate,  Object? arguments)?  pushNamed,TResult? Function( WidgetBuilder builder,  Completer<T?> completer,  RouteSettings? routeSettings)?  pushReplacement,TResult? Function( String route,  Completer<T?> completer,  Object? arguments)?  pushReplacementNamed,TResult? Function( T? result)?  pop,TResult? Function( RoutePredicate predicate)?  popUntil,TResult? Function( SnackBar snackbar)?  snackBar,TResult? Function()?  showLoading,TResult? Function()?  hideLoading,TResult? Function( WidgetBuilder builder,  Completer<T?> completer,  Color? backgroundColor,  double? elevation,  ShapeBorder? shape,  Clip? clipBehavior,  BoxConstraints? constraints,  Color? barrierColor,  bool isScrollControlled,  bool useRootNavigator,  bool isDismissible,  bool enableDrag,  RouteSettings? routeSettings,  AnimationController? transitionAnimationController,  Offset? anchorPoint)?  bottomSheet,TResult? Function( OverlayEntry entry)?  overlay,}) {final _that = this;
switch (_that) {
case _Dialog() when dialog != null:
return dialog(_that.completer,_that.pageBuilder,_that.barrierDismissible,_that.barrierLabel,_that.barrierColor,_that.transitionDuration,_that.transitionBuilder,_that.useRootNavigator,_that.routeSettings);case _Push() when push != null:
return push(_that.builder,_that.completer,_that.predicate,_that.routeSettings);case _AdaptivePush() when adaptivePush != null:
return adaptivePush(_that.builder,_that.completer,_that.routeSettings);case _PushNamed() when pushNamed != null:
return pushNamed(_that.route,_that.completer,_that.predicate,_that.arguments);case _PushReplacement() when pushReplacement != null:
return pushReplacement(_that.builder,_that.completer,_that.routeSettings);case _PushReplacementNamed() when pushReplacementNamed != null:
return pushReplacementNamed(_that.route,_that.completer,_that.arguments);case _Pop() when pop != null:
return pop(_that.result);case _PopUntil() when popUntil != null:
return popUntil(_that.predicate);case _SnackBar() when snackBar != null:
return snackBar(_that.snackbar);case _ShowLoading() when showLoading != null:
return showLoading();case _HideLoading() when hideLoading != null:
return hideLoading();case _BottomSheet() when bottomSheet != null:
return bottomSheet(_that.builder,_that.completer,_that.backgroundColor,_that.elevation,_that.shape,_that.clipBehavior,_that.constraints,_that.barrierColor,_that.isScrollControlled,_that.useRootNavigator,_that.isDismissible,_that.enableDrag,_that.routeSettings,_that.transitionAnimationController,_that.anchorPoint);case _Overlay() when overlay != null:
return overlay(_that.entry);case _:
  return null;

}
}

}

/// @nodoc


class _Dialog<T> extends NavigationEvent<T> {
  const _Dialog({required this.completer, required this.pageBuilder, this.barrierDismissible = true, this.barrierLabel = '', this.barrierColor = const Color(0x80000000), this.transitionDuration = AppTheme.defaultDuration, this.transitionBuilder, this.useRootNavigator = false, this.routeSettings}): super._();
  

 final  Completer<T?> completer;
 final  WidgetBuilder pageBuilder;
@JsonKey() final  bool barrierDismissible;
@JsonKey() final  String? barrierLabel;
@JsonKey() final  Color barrierColor;
@JsonKey() final  Duration transitionDuration;
 final  RouteTransitionsBuilder? transitionBuilder;
@JsonKey() final  bool useRootNavigator;
 final  RouteSettings? routeSettings;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DialogCopyWith<T, _Dialog<T>> get copyWith => __$DialogCopyWithImpl<T, _Dialog<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Dialog<T>&&(identical(other.completer, completer) || other.completer == completer)&&(identical(other.pageBuilder, pageBuilder) || other.pageBuilder == pageBuilder)&&(identical(other.barrierDismissible, barrierDismissible) || other.barrierDismissible == barrierDismissible)&&(identical(other.barrierLabel, barrierLabel) || other.barrierLabel == barrierLabel)&&(identical(other.barrierColor, barrierColor) || other.barrierColor == barrierColor)&&(identical(other.transitionDuration, transitionDuration) || other.transitionDuration == transitionDuration)&&(identical(other.transitionBuilder, transitionBuilder) || other.transitionBuilder == transitionBuilder)&&(identical(other.useRootNavigator, useRootNavigator) || other.useRootNavigator == useRootNavigator)&&(identical(other.routeSettings, routeSettings) || other.routeSettings == routeSettings));
}


@override
int get hashCode => Object.hash(runtimeType,completer,pageBuilder,barrierDismissible,barrierLabel,barrierColor,transitionDuration,transitionBuilder,useRootNavigator,routeSettings);

@override
String toString() {
  return 'NavigationEvent<$T>.dialog(completer: $completer, pageBuilder: $pageBuilder, barrierDismissible: $barrierDismissible, barrierLabel: $barrierLabel, barrierColor: $barrierColor, transitionDuration: $transitionDuration, transitionBuilder: $transitionBuilder, useRootNavigator: $useRootNavigator, routeSettings: $routeSettings)';
}


}

/// @nodoc
abstract mixin class _$DialogCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$DialogCopyWith(_Dialog<T> value, $Res Function(_Dialog<T>) _then) = __$DialogCopyWithImpl;
@useResult
$Res call({
 Completer<T?> completer, WidgetBuilder pageBuilder, bool barrierDismissible, String? barrierLabel, Color barrierColor, Duration transitionDuration, RouteTransitionsBuilder? transitionBuilder, bool useRootNavigator, RouteSettings? routeSettings
});




}
/// @nodoc
class __$DialogCopyWithImpl<T,$Res>
    implements _$DialogCopyWith<T, $Res> {
  __$DialogCopyWithImpl(this._self, this._then);

  final _Dialog<T> _self;
  final $Res Function(_Dialog<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? completer = null,Object? pageBuilder = null,Object? barrierDismissible = null,Object? barrierLabel = freezed,Object? barrierColor = null,Object? transitionDuration = null,Object? transitionBuilder = freezed,Object? useRootNavigator = null,Object? routeSettings = freezed,}) {
  return _then(_Dialog<T>(
completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,pageBuilder: null == pageBuilder ? _self.pageBuilder : pageBuilder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,barrierDismissible: null == barrierDismissible ? _self.barrierDismissible : barrierDismissible // ignore: cast_nullable_to_non_nullable
as bool,barrierLabel: freezed == barrierLabel ? _self.barrierLabel : barrierLabel // ignore: cast_nullable_to_non_nullable
as String?,barrierColor: null == barrierColor ? _self.barrierColor : barrierColor // ignore: cast_nullable_to_non_nullable
as Color,transitionDuration: null == transitionDuration ? _self.transitionDuration : transitionDuration // ignore: cast_nullable_to_non_nullable
as Duration,transitionBuilder: freezed == transitionBuilder ? _self.transitionBuilder : transitionBuilder // ignore: cast_nullable_to_non_nullable
as RouteTransitionsBuilder?,useRootNavigator: null == useRootNavigator ? _self.useRootNavigator : useRootNavigator // ignore: cast_nullable_to_non_nullable
as bool,routeSettings: freezed == routeSettings ? _self.routeSettings : routeSettings // ignore: cast_nullable_to_non_nullable
as RouteSettings?,
  ));
}


}

/// @nodoc


class _Push<T> extends NavigationEvent<T> {
  const _Push(this.builder, {required this.completer, this.predicate, this.routeSettings}): super._();
  

 final  WidgetBuilder builder;
 final  Completer<T?> completer;
 final  RoutePredicate? predicate;
 final  RouteSettings? routeSettings;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushCopyWith<T, _Push<T>> get copyWith => __$PushCopyWithImpl<T, _Push<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Push<T>&&(identical(other.builder, builder) || other.builder == builder)&&(identical(other.completer, completer) || other.completer == completer)&&(identical(other.predicate, predicate) || other.predicate == predicate)&&(identical(other.routeSettings, routeSettings) || other.routeSettings == routeSettings));
}


@override
int get hashCode => Object.hash(runtimeType,builder,completer,predicate,routeSettings);

@override
String toString() {
  return 'NavigationEvent<$T>.push(builder: $builder, completer: $completer, predicate: $predicate, routeSettings: $routeSettings)';
}


}

/// @nodoc
abstract mixin class _$PushCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$PushCopyWith(_Push<T> value, $Res Function(_Push<T>) _then) = __$PushCopyWithImpl;
@useResult
$Res call({
 WidgetBuilder builder, Completer<T?> completer, RoutePredicate? predicate, RouteSettings? routeSettings
});




}
/// @nodoc
class __$PushCopyWithImpl<T,$Res>
    implements _$PushCopyWith<T, $Res> {
  __$PushCopyWithImpl(this._self, this._then);

  final _Push<T> _self;
  final $Res Function(_Push<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? builder = null,Object? completer = null,Object? predicate = freezed,Object? routeSettings = freezed,}) {
  return _then(_Push<T>(
null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,predicate: freezed == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as RoutePredicate?,routeSettings: freezed == routeSettings ? _self.routeSettings : routeSettings // ignore: cast_nullable_to_non_nullable
as RouteSettings?,
  ));
}


}

/// @nodoc


class _AdaptivePush<T> extends NavigationEvent<T> {
  const _AdaptivePush(this.builder, {required this.completer, this.routeSettings}): super._();
  

 final  WidgetBuilder builder;
 final  Completer<T?> completer;
 final  RouteSettings? routeSettings;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdaptivePushCopyWith<T, _AdaptivePush<T>> get copyWith => __$AdaptivePushCopyWithImpl<T, _AdaptivePush<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdaptivePush<T>&&(identical(other.builder, builder) || other.builder == builder)&&(identical(other.completer, completer) || other.completer == completer)&&(identical(other.routeSettings, routeSettings) || other.routeSettings == routeSettings));
}


@override
int get hashCode => Object.hash(runtimeType,builder,completer,routeSettings);

@override
String toString() {
  return 'NavigationEvent<$T>.adaptivePush(builder: $builder, completer: $completer, routeSettings: $routeSettings)';
}


}

/// @nodoc
abstract mixin class _$AdaptivePushCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$AdaptivePushCopyWith(_AdaptivePush<T> value, $Res Function(_AdaptivePush<T>) _then) = __$AdaptivePushCopyWithImpl;
@useResult
$Res call({
 WidgetBuilder builder, Completer<T?> completer, RouteSettings? routeSettings
});




}
/// @nodoc
class __$AdaptivePushCopyWithImpl<T,$Res>
    implements _$AdaptivePushCopyWith<T, $Res> {
  __$AdaptivePushCopyWithImpl(this._self, this._then);

  final _AdaptivePush<T> _self;
  final $Res Function(_AdaptivePush<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? builder = null,Object? completer = null,Object? routeSettings = freezed,}) {
  return _then(_AdaptivePush<T>(
null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,routeSettings: freezed == routeSettings ? _self.routeSettings : routeSettings // ignore: cast_nullable_to_non_nullable
as RouteSettings?,
  ));
}


}

/// @nodoc


class _PushNamed<T> extends NavigationEvent<T> {
  const _PushNamed(this.route, {required this.completer, this.predicate, this.arguments}): super._();
  

 final  String route;
 final  Completer<T?> completer;
 final  RoutePredicate? predicate;
 final  Object? arguments;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushNamedCopyWith<T, _PushNamed<T>> get copyWith => __$PushNamedCopyWithImpl<T, _PushNamed<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushNamed<T>&&(identical(other.route, route) || other.route == route)&&(identical(other.completer, completer) || other.completer == completer)&&(identical(other.predicate, predicate) || other.predicate == predicate)&&const DeepCollectionEquality().equals(other.arguments, arguments));
}


@override
int get hashCode => Object.hash(runtimeType,route,completer,predicate,const DeepCollectionEquality().hash(arguments));

@override
String toString() {
  return 'NavigationEvent<$T>.pushNamed(route: $route, completer: $completer, predicate: $predicate, arguments: $arguments)';
}


}

/// @nodoc
abstract mixin class _$PushNamedCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$PushNamedCopyWith(_PushNamed<T> value, $Res Function(_PushNamed<T>) _then) = __$PushNamedCopyWithImpl;
@useResult
$Res call({
 String route, Completer<T?> completer, RoutePredicate? predicate, Object? arguments
});




}
/// @nodoc
class __$PushNamedCopyWithImpl<T,$Res>
    implements _$PushNamedCopyWith<T, $Res> {
  __$PushNamedCopyWithImpl(this._self, this._then);

  final _PushNamed<T> _self;
  final $Res Function(_PushNamed<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? route = null,Object? completer = null,Object? predicate = freezed,Object? arguments = freezed,}) {
  return _then(_PushNamed<T>(
null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,predicate: freezed == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as RoutePredicate?,arguments: freezed == arguments ? _self.arguments : arguments ,
  ));
}


}

/// @nodoc


class _PushReplacement<T> extends NavigationEvent<T> {
  const _PushReplacement(this.builder, {required this.completer, this.routeSettings}): super._();
  

 final  WidgetBuilder builder;
 final  Completer<T?> completer;
 final  RouteSettings? routeSettings;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushReplacementCopyWith<T, _PushReplacement<T>> get copyWith => __$PushReplacementCopyWithImpl<T, _PushReplacement<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushReplacement<T>&&(identical(other.builder, builder) || other.builder == builder)&&(identical(other.completer, completer) || other.completer == completer)&&(identical(other.routeSettings, routeSettings) || other.routeSettings == routeSettings));
}


@override
int get hashCode => Object.hash(runtimeType,builder,completer,routeSettings);

@override
String toString() {
  return 'NavigationEvent<$T>.pushReplacement(builder: $builder, completer: $completer, routeSettings: $routeSettings)';
}


}

/// @nodoc
abstract mixin class _$PushReplacementCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$PushReplacementCopyWith(_PushReplacement<T> value, $Res Function(_PushReplacement<T>) _then) = __$PushReplacementCopyWithImpl;
@useResult
$Res call({
 WidgetBuilder builder, Completer<T?> completer, RouteSettings? routeSettings
});




}
/// @nodoc
class __$PushReplacementCopyWithImpl<T,$Res>
    implements _$PushReplacementCopyWith<T, $Res> {
  __$PushReplacementCopyWithImpl(this._self, this._then);

  final _PushReplacement<T> _self;
  final $Res Function(_PushReplacement<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? builder = null,Object? completer = null,Object? routeSettings = freezed,}) {
  return _then(_PushReplacement<T>(
null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,routeSettings: freezed == routeSettings ? _self.routeSettings : routeSettings // ignore: cast_nullable_to_non_nullable
as RouteSettings?,
  ));
}


}

/// @nodoc


class _PushReplacementNamed<T> extends NavigationEvent<T> {
  const _PushReplacementNamed(this.route, {required this.completer, this.arguments}): super._();
  

 final  String route;
 final  Completer<T?> completer;
 final  Object? arguments;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PushReplacementNamedCopyWith<T, _PushReplacementNamed<T>> get copyWith => __$PushReplacementNamedCopyWithImpl<T, _PushReplacementNamed<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PushReplacementNamed<T>&&(identical(other.route, route) || other.route == route)&&(identical(other.completer, completer) || other.completer == completer)&&const DeepCollectionEquality().equals(other.arguments, arguments));
}


@override
int get hashCode => Object.hash(runtimeType,route,completer,const DeepCollectionEquality().hash(arguments));

@override
String toString() {
  return 'NavigationEvent<$T>.pushReplacementNamed(route: $route, completer: $completer, arguments: $arguments)';
}


}

/// @nodoc
abstract mixin class _$PushReplacementNamedCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$PushReplacementNamedCopyWith(_PushReplacementNamed<T> value, $Res Function(_PushReplacementNamed<T>) _then) = __$PushReplacementNamedCopyWithImpl;
@useResult
$Res call({
 String route, Completer<T?> completer, Object? arguments
});




}
/// @nodoc
class __$PushReplacementNamedCopyWithImpl<T,$Res>
    implements _$PushReplacementNamedCopyWith<T, $Res> {
  __$PushReplacementNamedCopyWithImpl(this._self, this._then);

  final _PushReplacementNamed<T> _self;
  final $Res Function(_PushReplacementNamed<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? route = null,Object? completer = null,Object? arguments = freezed,}) {
  return _then(_PushReplacementNamed<T>(
null == route ? _self.route : route // ignore: cast_nullable_to_non_nullable
as String,completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,arguments: freezed == arguments ? _self.arguments : arguments ,
  ));
}


}

/// @nodoc


class _Pop<T> extends NavigationEvent<T> {
  const _Pop({this.result}): super._();
  

 final  T? result;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PopCopyWith<T, _Pop<T>> get copyWith => __$PopCopyWithImpl<T, _Pop<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pop<T>&&const DeepCollectionEquality().equals(other.result, result));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(result));

@override
String toString() {
  return 'NavigationEvent<$T>.pop(result: $result)';
}


}

/// @nodoc
abstract mixin class _$PopCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$PopCopyWith(_Pop<T> value, $Res Function(_Pop<T>) _then) = __$PopCopyWithImpl;
@useResult
$Res call({
 T? result
});




}
/// @nodoc
class __$PopCopyWithImpl<T,$Res>
    implements _$PopCopyWith<T, $Res> {
  __$PopCopyWithImpl(this._self, this._then);

  final _Pop<T> _self;
  final $Res Function(_Pop<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? result = freezed,}) {
  return _then(_Pop<T>(
result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}


}

/// @nodoc


class _PopUntil<T> extends NavigationEvent<T> {
  const _PopUntil(this.predicate): super._();
  

 final  RoutePredicate predicate;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PopUntilCopyWith<T, _PopUntil<T>> get copyWith => __$PopUntilCopyWithImpl<T, _PopUntil<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PopUntil<T>&&(identical(other.predicate, predicate) || other.predicate == predicate));
}


@override
int get hashCode => Object.hash(runtimeType,predicate);

@override
String toString() {
  return 'NavigationEvent<$T>.popUntil(predicate: $predicate)';
}


}

/// @nodoc
abstract mixin class _$PopUntilCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$PopUntilCopyWith(_PopUntil<T> value, $Res Function(_PopUntil<T>) _then) = __$PopUntilCopyWithImpl;
@useResult
$Res call({
 RoutePredicate predicate
});




}
/// @nodoc
class __$PopUntilCopyWithImpl<T,$Res>
    implements _$PopUntilCopyWith<T, $Res> {
  __$PopUntilCopyWithImpl(this._self, this._then);

  final _PopUntil<T> _self;
  final $Res Function(_PopUntil<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? predicate = null,}) {
  return _then(_PopUntil<T>(
null == predicate ? _self.predicate : predicate // ignore: cast_nullable_to_non_nullable
as RoutePredicate,
  ));
}


}

/// @nodoc


class _SnackBar<T> extends NavigationEvent<T> {
  const _SnackBar(this.snackbar): super._();
  

 final  SnackBar snackbar;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SnackBarCopyWith<T, _SnackBar<T>> get copyWith => __$SnackBarCopyWithImpl<T, _SnackBar<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SnackBar<T>&&(identical(other.snackbar, snackbar) || other.snackbar == snackbar));
}


@override
int get hashCode => Object.hash(runtimeType,snackbar);

@override
String toString() {
  return 'NavigationEvent<$T>.snackBar(snackbar: $snackbar)';
}


}

/// @nodoc
abstract mixin class _$SnackBarCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$SnackBarCopyWith(_SnackBar<T> value, $Res Function(_SnackBar<T>) _then) = __$SnackBarCopyWithImpl;
@useResult
$Res call({
 SnackBar snackbar
});




}
/// @nodoc
class __$SnackBarCopyWithImpl<T,$Res>
    implements _$SnackBarCopyWith<T, $Res> {
  __$SnackBarCopyWithImpl(this._self, this._then);

  final _SnackBar<T> _self;
  final $Res Function(_SnackBar<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? snackbar = null,}) {
  return _then(_SnackBar<T>(
null == snackbar ? _self.snackbar : snackbar // ignore: cast_nullable_to_non_nullable
as SnackBar,
  ));
}


}

/// @nodoc


class _ShowLoading<T> extends NavigationEvent<T> {
  const _ShowLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShowLoading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NavigationEvent<$T>.showLoading()';
}


}




/// @nodoc


class _HideLoading<T> extends NavigationEvent<T> {
  const _HideLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HideLoading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NavigationEvent<$T>.hideLoading()';
}


}




/// @nodoc


class _BottomSheet<T> extends NavigationEvent<T> {
  const _BottomSheet({required this.builder, required this.completer, this.backgroundColor, this.elevation, this.shape, this.clipBehavior, this.constraints, this.barrierColor, this.isScrollControlled = false, this.useRootNavigator = false, this.isDismissible = true, this.enableDrag = true, this.routeSettings, this.transitionAnimationController, this.anchorPoint}): super._();
  

 final  WidgetBuilder builder;
 final  Completer<T?> completer;
 final  Color? backgroundColor;
 final  double? elevation;
 final  ShapeBorder? shape;
 final  Clip? clipBehavior;
 final  BoxConstraints? constraints;
 final  Color? barrierColor;
@JsonKey() final  bool isScrollControlled;
@JsonKey() final  bool useRootNavigator;
@JsonKey() final  bool isDismissible;
@JsonKey() final  bool enableDrag;
 final  RouteSettings? routeSettings;
 final  AnimationController? transitionAnimationController;
 final  Offset? anchorPoint;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BottomSheetCopyWith<T, _BottomSheet<T>> get copyWith => __$BottomSheetCopyWithImpl<T, _BottomSheet<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BottomSheet<T>&&(identical(other.builder, builder) || other.builder == builder)&&(identical(other.completer, completer) || other.completer == completer)&&(identical(other.backgroundColor, backgroundColor) || other.backgroundColor == backgroundColor)&&(identical(other.elevation, elevation) || other.elevation == elevation)&&(identical(other.shape, shape) || other.shape == shape)&&(identical(other.clipBehavior, clipBehavior) || other.clipBehavior == clipBehavior)&&(identical(other.constraints, constraints) || other.constraints == constraints)&&(identical(other.barrierColor, barrierColor) || other.barrierColor == barrierColor)&&(identical(other.isScrollControlled, isScrollControlled) || other.isScrollControlled == isScrollControlled)&&(identical(other.useRootNavigator, useRootNavigator) || other.useRootNavigator == useRootNavigator)&&(identical(other.isDismissible, isDismissible) || other.isDismissible == isDismissible)&&(identical(other.enableDrag, enableDrag) || other.enableDrag == enableDrag)&&(identical(other.routeSettings, routeSettings) || other.routeSettings == routeSettings)&&(identical(other.transitionAnimationController, transitionAnimationController) || other.transitionAnimationController == transitionAnimationController)&&(identical(other.anchorPoint, anchorPoint) || other.anchorPoint == anchorPoint));
}


@override
int get hashCode => Object.hash(runtimeType,builder,completer,backgroundColor,elevation,shape,clipBehavior,constraints,barrierColor,isScrollControlled,useRootNavigator,isDismissible,enableDrag,routeSettings,transitionAnimationController,anchorPoint);

@override
String toString() {
  return 'NavigationEvent<$T>.bottomSheet(builder: $builder, completer: $completer, backgroundColor: $backgroundColor, elevation: $elevation, shape: $shape, clipBehavior: $clipBehavior, constraints: $constraints, barrierColor: $barrierColor, isScrollControlled: $isScrollControlled, useRootNavigator: $useRootNavigator, isDismissible: $isDismissible, enableDrag: $enableDrag, routeSettings: $routeSettings, transitionAnimationController: $transitionAnimationController, anchorPoint: $anchorPoint)';
}


}

/// @nodoc
abstract mixin class _$BottomSheetCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$BottomSheetCopyWith(_BottomSheet<T> value, $Res Function(_BottomSheet<T>) _then) = __$BottomSheetCopyWithImpl;
@useResult
$Res call({
 WidgetBuilder builder, Completer<T?> completer, Color? backgroundColor, double? elevation, ShapeBorder? shape, Clip? clipBehavior, BoxConstraints? constraints, Color? barrierColor, bool isScrollControlled, bool useRootNavigator, bool isDismissible, bool enableDrag, RouteSettings? routeSettings, AnimationController? transitionAnimationController, Offset? anchorPoint
});




}
/// @nodoc
class __$BottomSheetCopyWithImpl<T,$Res>
    implements _$BottomSheetCopyWith<T, $Res> {
  __$BottomSheetCopyWithImpl(this._self, this._then);

  final _BottomSheet<T> _self;
  final $Res Function(_BottomSheet<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? builder = null,Object? completer = null,Object? backgroundColor = freezed,Object? elevation = freezed,Object? shape = freezed,Object? clipBehavior = freezed,Object? constraints = freezed,Object? barrierColor = freezed,Object? isScrollControlled = null,Object? useRootNavigator = null,Object? isDismissible = null,Object? enableDrag = null,Object? routeSettings = freezed,Object? transitionAnimationController = freezed,Object? anchorPoint = freezed,}) {
  return _then(_BottomSheet<T>(
builder: null == builder ? _self.builder : builder // ignore: cast_nullable_to_non_nullable
as WidgetBuilder,completer: null == completer ? _self.completer : completer // ignore: cast_nullable_to_non_nullable
as Completer<T?>,backgroundColor: freezed == backgroundColor ? _self.backgroundColor : backgroundColor // ignore: cast_nullable_to_non_nullable
as Color?,elevation: freezed == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double?,shape: freezed == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as ShapeBorder?,clipBehavior: freezed == clipBehavior ? _self.clipBehavior : clipBehavior // ignore: cast_nullable_to_non_nullable
as Clip?,constraints: freezed == constraints ? _self.constraints : constraints // ignore: cast_nullable_to_non_nullable
as BoxConstraints?,barrierColor: freezed == barrierColor ? _self.barrierColor : barrierColor // ignore: cast_nullable_to_non_nullable
as Color?,isScrollControlled: null == isScrollControlled ? _self.isScrollControlled : isScrollControlled // ignore: cast_nullable_to_non_nullable
as bool,useRootNavigator: null == useRootNavigator ? _self.useRootNavigator : useRootNavigator // ignore: cast_nullable_to_non_nullable
as bool,isDismissible: null == isDismissible ? _self.isDismissible : isDismissible // ignore: cast_nullable_to_non_nullable
as bool,enableDrag: null == enableDrag ? _self.enableDrag : enableDrag // ignore: cast_nullable_to_non_nullable
as bool,routeSettings: freezed == routeSettings ? _self.routeSettings : routeSettings // ignore: cast_nullable_to_non_nullable
as RouteSettings?,transitionAnimationController: freezed == transitionAnimationController ? _self.transitionAnimationController : transitionAnimationController // ignore: cast_nullable_to_non_nullable
as AnimationController?,anchorPoint: freezed == anchorPoint ? _self.anchorPoint : anchorPoint // ignore: cast_nullable_to_non_nullable
as Offset?,
  ));
}


}

/// @nodoc


class _Overlay<T> extends NavigationEvent<T> {
  const _Overlay(this.entry): super._();
  

 final  OverlayEntry entry;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverlayCopyWith<T, _Overlay<T>> get copyWith => __$OverlayCopyWithImpl<T, _Overlay<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Overlay<T>&&(identical(other.entry, entry) || other.entry == entry));
}


@override
int get hashCode => Object.hash(runtimeType,entry);

@override
String toString() {
  return 'NavigationEvent<$T>.overlay(entry: $entry)';
}


}

/// @nodoc
abstract mixin class _$OverlayCopyWith<T,$Res> implements $NavigationEventCopyWith<T, $Res> {
  factory _$OverlayCopyWith(_Overlay<T> value, $Res Function(_Overlay<T>) _then) = __$OverlayCopyWithImpl;
@useResult
$Res call({
 OverlayEntry entry
});




}
/// @nodoc
class __$OverlayCopyWithImpl<T,$Res>
    implements _$OverlayCopyWith<T, $Res> {
  __$OverlayCopyWithImpl(this._self, this._then);

  final _Overlay<T> _self;
  final $Res Function(_Overlay<T>) _then;

/// Create a copy of NavigationEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = null,}) {
  return _then(_Overlay<T>(
null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as OverlayEntry,
  ));
}


}

// dart format on
