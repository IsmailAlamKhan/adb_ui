import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'logger.dart';

mixin Event {}

final eventBusProvider = Provider<EventBus>((_) => EventBus()..init());

class EventBus {
  final _streamController = StreamController<Event>.broadcast();
  Stream<Event> get stream => _streamController.stream;
  void emit(Event event) => _streamController.add(event);
  void emitAll(List<Event> events) {
    for (final event in events) {
      emit(event);
    }
  }

  StreamSubscription<Event> on<T>(void Function(T) callback) =>
      _streamController.stream.listen((event) {
        if (event is T) {
          callback(event as T);
        }
      });

  StreamSubscription<Event> onAll(
    void Function(Event) callback,
    List<Type> types,
  ) =>
      _streamController.stream.listen((event) {
        for (final refetchEventType in types) {
          if (event.runtimeType == refetchEventType) {
            callback(event);
          }
        }
      });

  void init() {
    _streamController.stream.listen((event) {
      logInfo('---Event arrived: $event---');
    });
  }
}

class EventListener<T extends Event> extends HookConsumerWidget {
  const EventListener({
    super.key,
    required this.onEvent,
    required this.child,
  });
  final void Function(T) onEvent;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventEmitter = ref.read(eventBusProvider);
    useEffect(() {
      final subscription = eventEmitter.on<T>(onEvent);
      return subscription.cancel;
    }, [onEvent]);
    return child;
  }
}

class MultiEventListener extends HookConsumerWidget {
  const MultiEventListener({
    super.key,
    required this.events,
    required this.onEvent,
    required this.child,
  });
  final List<Type> events;
  final void Function(Event event) onEvent;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventEmitter = ref.read(eventBusProvider);
    useEffect(() {
      final subscription = eventEmitter.stream.listen((event) {
        if (events.contains(event.runtimeType)) {
          onEvent(event);
        }
      });
      return subscription.cancel;
    }, [onEvent, events]);
    return child;
  }
}
