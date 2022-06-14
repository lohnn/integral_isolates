import 'dart:async';

import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

abstract class BackpressureStrategy {
  const BackpressureStrategy();

  Stream<MapEntry<Completer, IsolateConfiguration>> get stream;

  void add(MapEntry<Completer, IsolateConfiguration> configuration);

  void dispose();

  @visibleForTesting
  void drop(MapEntry<Completer, IsolateConfiguration> configuration) {
    configuration.key.completeError(
      Exception('Dropped due to backpressure'),
    );
  }
}
