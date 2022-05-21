// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:integral_isolates/src/backpressure/backpressure.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';

class DiscardNewBackPressure extends Backpressure {
  final StreamController<MapEntry<Completer, IsolateConfiguration>>
      _controller =
      StreamController<MapEntry<Completer, IsolateConfiguration>>();
  late final Stream<MapEntry<Completer, IsolateConfiguration>> _stream =
      _controller.stream;

  bool isRunning = false;

  Stream<MapEntry<Completer, IsolateConfiguration>> stream() async* {
    await for (final configuration in _stream) {
      isRunning = false;
      yield configuration;
    }
  }

  void add(MapEntry<Completer, IsolateConfiguration> configuration) {
    if (isRunning) {
      drop(configuration);
    } else {
      isRunning = true;
      _controller.add(configuration);
    }
  }

  void dispose() {
    _controller.close();
  }
}
