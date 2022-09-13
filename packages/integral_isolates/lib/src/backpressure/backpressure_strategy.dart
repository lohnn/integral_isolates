import 'dart:async';

import 'package:integral_isolates/src/isolate_configuration.dart';

typedef BackpressureConfiguration = MapEntry<Completer, IsolateConfiguration>;

abstract class BackpressureStrategy {
  const BackpressureStrategy();

  bool hasNext();

  BackpressureConfiguration takeNext();

  void add(BackpressureConfiguration configuration);

  void dispose();

  void drop(BackpressureConfiguration configuration) {
    configuration.key.completeError(
      Exception('Dropped due to backpressure'),
    );
  }
}
