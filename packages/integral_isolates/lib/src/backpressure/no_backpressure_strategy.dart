import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';

/// An implementation of [BackpressureStrategy] that uses a FIFO stack for
/// handling backpressure.
///
/// This strategy has the potential of overflowing the memory as it just keeps
/// piling them up, without discarding any jobs while running.
///
/// Marble diagram to visualize timeline:
///
/// --a---b---c---d---e---f---------------|
///
/// ------a-----b-----c-----d-----e-----f-|
class NoBackPressureStrategy<Q, R> extends BackpressureStrategy<Q, R> {
  final List<BackpressureConfiguration<Q, R>> _backstack = [];

  @override
  void add(BackpressureConfiguration<Q, R> configuration) {
    _backstack.add(configuration);
  }

  @override
  bool hasNext() {
    return _backstack.isNotEmpty;
  }

  @override
  BackpressureConfiguration<Q, R> takeNext() {
    return _backstack.removeAt(0);
  }

  @override
  void dispose() {
    _backstack.forEach(drop);
    _backstack.clear();
  }
}
