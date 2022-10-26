import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../utils/utils.dart';
import '../shared.dart';

enum AlertType { success, error }

class Alert extends StatelessWidget {
  const Alert({
    super.key,
    required this.title,
    this.messege,
    this.type = AlertType.success,
  });
  final String title;
  final String? messege;
  final AlertType type;

  const factory Alert.error({required String title, String? messege}) = _ErrorAlert;

  const factory Alert.success({required String title, String? messege}) = _SuccessAlert;

  void showWith({
    required void Function(WidgetBuilder, RouteSettings, Timer) show,
    required VoidCallback hide,
  }) {
    final timer = Timer(const Duration(seconds: 3), () {
      logInfo('5 SECONDS');
      hide();
    });

    show((_) => this, const RouteSettings(name: 'confirm'), timer);
  }

  static void hideWith(
    void Function(RoutePredicate predicate) hide,
  ) =>
      hide((route) => route.settings.name != 'confirm');

  Future<void> showWithNavigatorState(NavigatorState navigator) async => showWith(
        show: (builder, settings, timer) => navigator
            .showDialog(
          pageBuilder: builder,
          routeSettings: settings,
        )
            .then((value) {
          if (timer.isActive) {
            timer.cancel();
          }
        }),
        hide: () => hideWithNavigatorState(navigator),
      );

  static void hideWithNavigatorState(NavigatorState navigator) => hideWith(navigator.popUntil);

  Future<void> show(BuildContext context) => showWithNavigatorState(Navigator.of(context));

  static void hide(BuildContext context) => hideWithNavigatorState(Navigator.of(context));

  @override
  Widget build(BuildContext context) {
    String lottieAsset;
    switch (type) {
      case AlertType.error:
        lottieAsset = 'assets/lottie/error.json';
        break;
      case AlertType.success:
        lottieAsset = 'assets/lottie/success.json';
        break;
    }
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 80,
              child: Lottie.asset(lottieAsset, repeat: false),
            ),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const Gap(10),
            if (messege != null) ...[
              Text(messege!, style: Theme.of(context).textTheme.bodyText2),
              const Gap(10),
            ],
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  minimumSize: const Size(100, 35),
                ).filled(context),
                onPressed: () => hideWith(Navigator.of(context).popUntil),
                child: const Text('OK'),
              ),
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }
}

class _ErrorAlert extends Alert {
  const _ErrorAlert({
    super.key,
    required super.title,
    super.messege,
  }) : super(type: AlertType.error);
}

class _SuccessAlert extends Alert {
  const _SuccessAlert({
    super.key,
    required super.title,
    super.messege,
  }) : super(type: AlertType.success);
}
