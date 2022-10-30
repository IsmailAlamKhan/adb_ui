import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../shared.dart';

class NavigationEventListener extends HookConsumerWidget {
  const NavigationEventListener({
    super.key,
    required this.child,
    required this.navigator,
    this.onPop,
  });
  final Widget child;
  final GlobalKey<NavigatorState> navigator;
  final void Function(Object)? onPop;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventBus = ref.watch(eventBusProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    useEffect(() {
      final subscription = eventBus.on<NavigationEvent>((event) {
        final navigator = this.navigator.currentState!;
        event.when(
          overlay: (overlay) => navigator.overlay!.insert(overlay),
          bottomSheet: (
            builder,
            completer,
            backgroundColor,
            elevation,
            shape,
            clipBehavior,
            constraints,
            barrierColor,
            isScrollControlled,
            useRootNavigator,
            isDismissible,
            enableDrag,
            routeSettings,
            transitionAnimationController,
            anchorPoint,
          ) =>
              showModalBottomSheet(
            context: navigator.context,
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
            anchorPoint: anchorPoint,
          ).then(completer.complete),
          dialog: (
            completer,
            pageBuilder,
            barrierDismissible,
            barrierLabel,
            barrierColor,
            transitionDuration,
            transitionBuilder,
            useRootNavigator,
            routeSettings,
          ) =>
              navigator
                  .showDialog(
                    pageBuilder: pageBuilder,
                    barrierDismissible: barrierDismissible,
                    barrierLabel: barrierLabel,
                    barrierColor: barrierColor,
                    transitionDuration: transitionDuration,
                    transitionBuilder: transitionBuilder,
                    useRootNavigator: useRootNavigator,
                    routeSettings: routeSettings,
                  )
                  .then(completer.complete),
          push: (route, completer, predicate, settings) {
            if (predicate != null) {
              navigator
                  .pushAndRemoveUntilBuilder(route, predicate, settings)
                  .then(completer.complete);
            } else {
              navigator.pushBuilder(route, settings).then(completer.complete);
            }
          },
          pushNamed: (route, completer, predict, args) {
            if (predict != null) {
              navigator
                  .pushNamedAndRemoveUntil(route, predict, arguments: args)
                  .then(completer.complete);
            } else {
              navigator.pushNamed(route, arguments: args).then(completer.complete);
            }
          },
          pop: (result) {
            if (onPop != null) {
              onPop!(result);
            } else {
              navigator.pop(result);
            }
          },
          popUntil: (predicate) => navigator.popUntil(predicate),
          snackBar: (snackbar) => scaffoldMessenger.showAppSnackbar(snackbar: snackbar),
          showLoading: () => navigator.showLoading(),
          hideLoading: () => navigator.hideLoading(),
          pushReplacement: (
            builder,
            completer,
            routeSettings,
          ) =>
              navigator.pushReplacementBuilder(builder, routeSettings).then(completer.complete),
          pushReplacementNamed: (
            route,
            completer,
            args,
          ) =>
              navigator.pushReplacementNamed(route, arguments: args).then(completer.complete),
          adaptivePush: (
            builder,
            completer,
            routeSettings,
          ) =>
              navigator.adaptivePush(builder, routeSettings).then(completer.complete),
        );
      });
      return subscription.cancel;
    }, []);
    return child;
  }
}
