import 'dart:async';

import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

abstract class Backpressure {
  @visibleForTesting
  void drop(MapEntry<Completer, IsolateConfiguration> configuration) {
    configuration.key.completeError(
      Exception('Dropped due to backpressure'),
    );
  }
}
