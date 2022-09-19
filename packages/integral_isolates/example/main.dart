// ignore_for_file: avoid_print

import 'dart:io';

import 'package:integral_isolates/integral_isolates.dart';

void main() async {
  final isolated = Isolated();

  /// Function that halts the thread while looping and printing.
  Future<void> threadSleepComputation(int input) async {
    for (var i = 0; i < 15; i++) {
      print("Look, ma. I'm not stopped! ($input)");
      sleep(const Duration(milliseconds: 200));
    }
  }

  // Running two instances of the halting function [threadSleepComputation] and
  // an isolate at the same time.
  final pi = (await Future.wait<dynamic>([
    Future.delayed(
      const Duration(milliseconds: 100),
      () => threadSleepComputation(1),
    ),
    isolated.isolate(leibnizPi, 500000000),
    Future.delayed(
      const Duration(milliseconds: 100),
      () => threadSleepComputation(2),
    ),
  ]))[1];

  print(pi);

  isolated.dispose();
}

/// Calculate PI and prints to log when done
double leibnizPi(int steps) {
  double x = 1.0;

  for (var i = 1; i < steps; i++) {
    if (i.isOdd) {
      x = x - (1.0 / ((2.0 * i) + 1));
    } else {
      x = x + (1.0 / ((2.0 * i) + 1));
    }
  }
  x = x * 4.0;
  print("Job's done!");
  return x;
}
