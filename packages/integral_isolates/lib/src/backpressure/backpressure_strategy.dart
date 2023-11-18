import 'dart:async';

import 'package:async/async.dart';
import 'package:integral_isolates/integral_isolates.dart';
import 'package:integral_isolates/src/integral_isolate_base.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

/// Base class for a job queue item.
///
/// Used internally to keep track of jobs waiting for execution.
///
/// Implementors:
/// * [FutureBackpressureConfiguration] that is used for the isolate calls that
/// returns a future.
/// * [StreamBackpressureConfiguration] that is used for the isolate calls that
/// returns a stream.
@internal
abstract class BackpressureConfiguration<Q, R> {
  /// Constructor for allowing overloading of this class, not to be used
  /// externally.
  @internal
  const BackpressureConfiguration(this.configuration);

  /// The [IsolateConfiguration] containing the configuration to be used to
  /// send to the isolate.
  final IsolateConfiguration<Q, R> configuration;

  /// Completes and closes the Stream or Future with an error and an optional
  /// stack trace.
  @internal
  void closeError(Object error, [StackTrace? stackTrace]);

  /// Copies the backpressure configuration with a new [configuration], keeping
  /// the old completer/streamController.
  BackpressureConfiguration<Q, R> copyWith(
    IsolateConfiguration<Q, R> isolateConfiguration,
  );

  /// Internal function that is called to let the [BackpressureConfiguration]
  /// implementation handle it's own response.
  @internal
  Future<void> handleResponse(StreamQueue<dynamic> isolateToMainPort);
}

/// Job queue item for use with the [StatefulIsolate.compute] and
/// [TailoredStatefulIsolate.compute] functions.
@internal
class FutureBackpressureConfiguration<Q, R>
    extends BackpressureConfiguration<Q, R> {
  /// Internal handle for completing the job.
  @internal
  final Completer<R> completer;

  /// Creates a job queue item for a [Future] response.
  @internal
  const FutureBackpressureConfiguration(this.completer, super.configuration);

  @override
  void closeError(Object error, [StackTrace? stackTrace]) {
    completer.completeError(error, stackTrace);
  }

  @override
  BackpressureConfiguration<Q, R> copyWith(
    IsolateConfiguration<Q, R> isolateConfiguration,
  ) {
    return FutureBackpressureConfiguration(completer, isolateConfiguration);
  }

  @override
  Future<void> handleResponse(StreamQueue<dynamic> isolateToMainPort) async {
    switch (await isolateToMainPort.next) {
      case SuccessIsolateResponse<R>(response: final response):
        completer.complete(response);
      case ErrorIsolateResponse(
          error: final error,
          stackTrace: final stackTrace,
        ):
        closeError(error, stackTrace);
      default:
        closeError(UnexpectedDropException());
    }
  }
}

/// Job queue item for use with the [StatefulIsolate.computeStream] and
/// [TailoredStatefulIsolate.computeStream] functions.
@internal
class StreamBackpressureConfiguration<Q, R>
    extends BackpressureConfiguration<Q, R> {
  /// Internal handle for sending stream events to the listener.
  @internal
  final StreamController<R> streamController;

  /// Creates a job queue item for a [Stream] response.
  @internal
  const StreamBackpressureConfiguration(
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
    return StreamBackpressureConfiguration(
      streamController,
      isolateConfiguration,
    );
  }

  @override
  Future<void> handleResponse(StreamQueue<dynamic> isolateToMainPort) async {
    while (true) {
      switch (await isolateToMainPort.next) {
        case PartialSuccessIsolateResponse<R>(response: final response):
          streamController.add(response);
        case StreamClosedIsolateResponse():
          streamController.close();
          return;
        case ErrorIsolateResponse(
            error: final error,
            stackTrace: final stackTrace,
          ):
          closeError(error, stackTrace);
          return;
        default:
          closeError(UnexpectedDropException());
      }
    }
  }
}

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
    configuration.closeError(const BackpressureDropException());
  }
}
