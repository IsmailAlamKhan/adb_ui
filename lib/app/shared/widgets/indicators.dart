// 🐦 Flutter imports:
import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../shared.dart';

class AppNoItemsIndicator extends StatelessWidget {
  const AppNoItemsIndicator({
    super.key,
    this.refresh,
    this.isCompact = false,
  });
  final FutureCallback? refresh;
  final bool isCompact;
  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return AppExceptionIndicatorCompact(onTryAgain: refresh, message: "Nothing to show");
    }
    return AppExceptionIndicator(
      title: "Nothing to show",
      onTryAgain: refresh,
    );
  }
}

class PaginationNewPageErrorIndicator extends StatelessWidget {
  const PaginationNewPageErrorIndicator({
    super.key,
    this.onTap,
  });
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 16),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Something went wrong please try again',
                  textAlign: TextAlign.center,
                ),
                Gap(4),
                Icon(Icons.refresh, size: 16),
              ],
            ),
          ),
        ),
      );
}

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
}

mixin _TryAgainWidget on StatefulWidget {
  abstract final FutureCallback? onTryAgain;
  abstract final bool? isLoading;
}

mixin _TryAgain<T extends _TryAgainWidget> on State<T> {
  bool isLoading = false;
  bool get effectiveIsLoading => widget.isLoading ?? isLoading;
  @override
  void setState(VoidCallback fn) {
    if (!mounted) {
      fn();
      return;
    }
    super.setState(fn);
  }

  VoidCallback? tryAgain() {
    if (!isLoading && widget.onTryAgain != null) {
      return () async {
        setState(() => isLoading = true);
        await widget.onTryAgain!();
        setState(() => isLoading = false);
      };
    }
  }
}

class AppExceptionIndicatorCompact extends StatefulWidget with _TryAgainWidget {
  const AppExceptionIndicatorCompact({
    super.key,
    this.message,
    this.messageWidget,
    this.onTryAgain,
    this.isLoading,
  });
  final String? message;
  final Widget? messageWidget;
  @override
  final FutureCallback? onTryAgain;
  @override
  final bool? isLoading;

  @override
  State<AppExceptionIndicatorCompact> createState() => _AppExceptionIndicatorCompactState();
}

class _AppExceptionIndicatorCompactState extends State<AppExceptionIndicatorCompact>
    with _TryAgain<AppExceptionIndicatorCompact> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.message!, maxLines: 3),
          const Gap(4),
          if (widget.onTryAgain != null)
            Card(
              margin: EdgeInsets.zero,
              shape: const CircleBorder(),
              child: effectiveIsLoading
                  ? const SizedBox(
                      height: 30, width: 30, child: CircularProgressIndicator(strokeWidth: 2))
                  : IconButton(icon: const Icon(Icons.refresh), onPressed: tryAgain()),
            ),
        ],
      ),
    );
  }
}

class AppExceptionIndicator extends StatefulWidget with _TryAgainWidget {
  const AppExceptionIndicator({
    this.title,
    this.titleWidget,
    this.message,
    this.messageWidget,
    this.onTryAgain,
    this.isLoading,
    this.extraAction,
    super.key,
  });

  final String? title;
  final Widget? titleWidget;
  final String? message;
  final Widget? messageWidget;
  @override
  final FutureCallback? onTryAgain;
  @override
  final bool? isLoading;
  final Widget? extraAction;

  @override
  State<AppExceptionIndicator> createState() => _AppExceptionIndicatorState();
}

class _AppExceptionIndicatorState extends State<AppExceptionIndicator>
    with _TryAgain<AppExceptionIndicator> {
  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall!,
              child: widget.titleWidget ??
                  Text(
                    widget.title ?? "Something went wrong",
                    textAlign: TextAlign.center,
                  ),
            ),
            if (message != null || widget.messageWidget != null) ...[
              const Gap(16),
              widget.messageWidget ?? Text(message!, textAlign: TextAlign.center),
            ],
            if (widget.extraAction != null) ...[const Gap(16), widget.extraAction!],
            if (widget.onTryAgain != null) ...[
              const Gap(48),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: tryAgain(),
                  // buttonType: !effectiveIsLoading ? ButtonType.filled : ButtonType.elevated,
                  style: ElevatedButton.styleFrom(
                    shape: !effectiveIsLoading ? null : const CircleBorder(),
                    minimumSize: const Size(150, 50),
                  ).filled(context),
                  child: effectiveIsLoading
                      ? const CircularProgressIndicator()
                      : const Text("Try again", style: TextStyle(fontSize: 16)),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class EffectiveSocialUppExceptionIndicator extends StatelessWidget {
  const EffectiveSocialUppExceptionIndicator({
    super.key,
    this.title,
    this.titleWidget,
    this.message,
    this.messageWidget,
    this.onTryAgain,
    this.isLoading,
  });
  final String? title;
  final Widget? titleWidget;
  final String? message;
  final Widget? messageWidget;
  final FutureCallback? onTryAgain;
  final bool? isLoading;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight > 300) {
          return AppExceptionIndicator(
            title: title,
            titleWidget: titleWidget,
            message: message,
            messageWidget: messageWidget,
            onTryAgain: onTryAgain,
            isLoading: isLoading,
          );
        }
        return Center(
          child: AppExceptionIndicatorCompact(
            message: message,
            messageWidget: messageWidget,
            onTryAgain: onTryAgain,
            isLoading: isLoading,
          ),
        );
      },
    );
  }
}
