import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';

class NoBackPressureStrategy extends BackpressureStrategy {
  final List<BackpressureConfiguration> _backstack = [];

  @override
  void add(BackpressureConfiguration configuration) {
    _backstack.add(configuration);
  }

  @override
  bool hasNext() {
    return _backstack.isNotEmpty;
  }

  @override
  BackpressureConfiguration takeNext() {
    return _backstack.removeAt(0);
  }

  @override
  void dispose() {
    _backstack.forEach(drop);
    _backstack.clear();
  }
}
