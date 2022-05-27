import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

class NoBackPressureStrategy extends BackpressureStrategy {
  final StreamController<MapEntry<Completer, IsolateConfiguration>> controller =
      StreamController();

  @override
  Stream<MapEntry<Completer, IsolateConfiguration>> get stream =>
      controller.stream;

  @override
  void add(MapEntry<Completer, IsolateConfiguration> configuration) {
    controller.add(configuration);
  }

  @override
  void dispose() {
    controller.close();
  }
}
