import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../utils/utils.dart';
import '../shared.dart';

abstract class AsyncValueBuilderBase<T> extends StatelessWidget {
  const AsyncValueBuilderBase({
    super.key,
    required this.value,
    required this.builder,
    this.errorBuilder,
    this.loadingBuilder,
    this.onTryAgain,
    this.isCompact = false,
  });
  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context, Object error, StackTrace? stackTrace)? errorBuilder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final bool isCompact;
  final FutureCallback? onTryAgain;

  static Widget _defaultLoadingBuilder(BuildContext context) => const AppLoadingIndicator();

  Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final message = exceptionToString(error);
    if (isCompact) {
      return AppExceptionIndicatorCompact(message: message, onTryAgain: onTryAgain);
    } else {
      return AppExceptionIndicator(message: message, onTryAgain: onTryAgain);
    }
  }
}

class AsyncValueBuilder<T> extends AsyncValueBuilderBase<T> {
  const AsyncValueBuilder({
    super.key,
    required super.value,
    required super.builder,
    super.errorBuilder,
    super.loadingBuilder,
    super.onTryAgain,
    super.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) => builder(context, data),
      loading: () => loadingBuilder?.call(context) ?? const AppLoadingIndicator(),
      error: (error, stackTrace) {
        return errorBuilder?.call(context, error, stackTrace) ??
            _defaultErrorBuilder(context, error, stackTrace);
      },
    );
  }
}

class SliverAsyncValueBuilder<T> extends AsyncValueBuilderBase<T> {
  const SliverAsyncValueBuilder({
    super.key,
    required super.value,
    required super.builder,
    super.errorBuilder,
    super.loadingBuilder,
    super.onTryAgain,
    super.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncValueBuilder<T>(
      value: value,
      builder: builder,
      errorBuilder: (context, error, stackTrace) {
        if (errorBuilder != null) {
          return errorBuilder!(context, error, stackTrace);
        } else {
          return SliverFillRemaining(child: _defaultErrorBuilder(context, error, stackTrace));
        }
      },
      loadingBuilder: (context) {
        if (loadingBuilder != null) {
          return loadingBuilder!(context);
        } else {
          return const SliverFillRemaining(child: AppLoadingIndicator());
        }
      },
      onTryAgain: onTryAgain,
      isCompact: isCompact,
    );
  }
}
