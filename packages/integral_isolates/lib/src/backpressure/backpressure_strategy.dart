import 'dart:async';

import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

/// A job queue item.
///
/// Used internally to keep track of jobs waiting for execution.
abstract class BackpressureConfiguration<Q, R> {
  // TODO(lohnn): Implement equals and hashCode

  const BackpressureConfiguration(this.configuration);

  final IsolateConfiguration<Q, R> configuration;

  void closeError(Object error, [StackTrace? stackTrace]);

  BackpressureConfiguration<Q, R> copyWith(
    IsolateConfiguration<Q, R> isolateConfiguration,
  );

  factory BackpressureConfiguration.future(
    Completer<R> completer,
    IsolateConfiguration<Q, R> configuration,
  ) = FutureBackpressureConfiguration._;

  factory BackpressureConfiguration.stream(
    StreamController<R> streamController,
    IsolateConfiguration<Q, R> configuration,
  ) = StreamBackpressureConfiguration._;
}

@internal
class FutureBackpressureConfiguration<Q, R>
    extends BackpressureConfiguration<Q, R> {
  // TODO(lohnn): Implement equals and hashCode

  final Completer<R> completer;

  const FutureBackpressureConfiguration._(this.completer, super.configuration);

  @override
  void closeError(Object error, [StackTrace? stackTrace]) {
    completer.completeError(error, stackTrace);
  }

  @override
  BackpressureConfiguration<Q, R> copyWith(
    IsolateConfiguration<Q, R> isolateConfiguration,
  ) {
    return FutureBackpressureConfiguration._(completer, isolateConfiguration);
  }
}

@internal
class StreamBackpressureConfiguration<Q, R>
    extends BackpressureConfiguration<Q, R> {
  // TODO(lohnn): Implement equals and hashCode

  final StreamController<R> streamController;

  const StreamBackpressureConfiguration._(
    this.streamController,
    super.configuration,
  );

  @override
  void closeError(Object error, [StackTrace? stackTrace]) {
    streamController.addError(error, stackTrace);
    streamController.close();
  }

  @override
  BackpressureConfiguration<Q, R> copyWith(
    IsolateConfiguration<Q, R> isolateConfiguration,
  ) {
    return StreamBackpressureConfiguration._(
      streamController,
      isolateConfiguration,
    );
  }
}

// typedef BackpressureConfiguration<Q, R>
//     = MapEntry<Completer<R>, IsolateConfiguration<Q, R>>;

/// Class to implement to support a backpressure strategy. This is used to make
/// sure job queues are handled properly.
///
/// Examples of implementations of this class are:
/// [NoBackPressureStrategy] that uses a FIFO stack for handling backpressure.
/// [ReplaceBackpressureStrategy] that has a job queue with size one, and
/// discards the queue upon adding a new job.
/// [DiscardNewBackPressureStrategy] that has a job queue with size one, and
/// as long as the queue is populated a new job will not be added.
/// [CombineBackPressureStrategy] that has a job queue with size one, and uses
/// a combine function to combine input data on back pressure.
abstract class BackpressureStrategy<Q, R> {
  /// Function that returns true if the back pressure strategy has a job in
  /// queue.
  bool hasNext();

  /// Function that returns the next job in queue.
  ///
  /// Always check [hasNext] before running this function, as this function
  /// has no guarantee that it will not throw exception if no items are in
  /// queue.
  BackpressureConfiguration<Q, R> takeNext();

  /// Adds another job to the queue.
  void add(BackpressureConfiguration<Q, R> configuration);

  /// Clears the queue and cleans up.
  ///
  /// Implementing this function, remember to [drop] all jobs in queue so all
  /// jobs will complete with at least a failure.
  void dispose();

  /// Drops the job item, completing it with an error.
  void drop(BackpressureConfiguration configuration) {
    configuration.closeError(BackpressureDropException());
  }
}
