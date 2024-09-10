import 'package:integral_isolates/src/backpressure/backpressure_strategy.dart';
import 'package:integral_isolates/src/backpressure/mixins/tailored_one_sized_queue.dart';

/// An implementation of [BackpressureStrategy] that allows for manual merge of
/// input data for calls to the isolate function.
///
/// This back pressure strategy uses the [_combineFunction] to merge the input
/// data from all calls to the isolate function on back pressure.
///
/// To create a tailored isolate that multiplies an integer input:
///
/// ```dart
/// final isolate = Isolated.tailored<int, int>(
///   backpressureStrategy: CombineBackPressureStrategy(
///     (oldData, newData) => oldData * newData,
///   ),
/// );
/// ```
///
/// Marble diagram to visualize timeline:
///
/// --a--b--c---d--e--f-g---------|
///
/// ---------a-b*c-------d--e*f*g-|
class CombineBackPressureStrategy<Q, R>
    extends TailoredBackpressureStrategy<Q, R> with TailoredOneSizedQueue {
  final Q Function(
    Q oldData,
    Q newData,
  ) _combineFunction;

  /// Creates a back pressure strategy that combines input data on back
  /// pressure.
  ///
  /// Keep in mind that, as this back pressure strategy always uses the newest
  /// callback when adding work, you always have to return data of the same type
  /// as the [newData] in the [_combineFunction].
  CombineBackPressureStrategy(this._combineFunction);

  @override
  void add(TailoredBackpressureConfiguration<Q, R> configuration) {
    if (hasNext()) {
      final queuedConfiguration = takeNext();
      drop(queuedConfiguration);

      final newMessage = _combineFunction(
        queuedConfiguration.configuration.message,
        configuration.configuration.message,
      );

      final combinedConfiguration = configuration.configuration.copyWith(
        message: newMessage,
      );

      queue = configuration.copyWith(combinedConfiguration);
    } else {
      queue = configuration;
    }
  }
}
