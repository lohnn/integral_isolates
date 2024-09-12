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
abstract class BackpressureConfiguration<R> {
  /// Constructor for allowing overloading of this class, not to be used
  /// externally.
  @internal
  const BackpressureConfiguration();

  /// The [IsolateConfiguration] containing the configuration to be used to
  /// send to the isolate.
  IsolateConfiguration<R> get configuration;

  /// Completes and closes the Stream or Future with an error and an optional
  /// stack trace.
  @internal
  void closeError(Object error, [StackTrace? stackTrace]);

  /// Internal function that is called to let the [BackpressureConfiguration]
  /// implementation handle it's own response.
  @internal
  Future<void> handleResponse(StreamQueue<dynamic> isolateToMainPort);
}

@internal
abstract class BackpressureRunConfiguration<R>
    extends BackpressureConfiguration<R> {
  /// The [IsolateConfiguration] containing the configuration to be used to
  /// send to the isolate.
  @override
  final IsolateConfiguration<R> configuration;

  const BackpressureRunConfiguration(this.configuration);
}

@internal
abstract class TailoredBackpressureConfiguration<Q, R>
    extends BackpressureConfiguration<R> {
  const TailoredBackpressureConfiguration(this.configuration);

  /// The [IsolateConfiguration] containing the configuration to be used to
  /// send to the isolate.
  @override
  final TailoredIsolateConfiguration<Q, R> configuration;

  /// Copies the backpressure configuration with a new [configuration], keeping
  /// the old completer/streamController.
  TailoredBackpressureConfiguration<Q, R> copyWith(
    TailoredIsolateConfiguration<Q, R> isolateConfiguration,
  );
}

/// Job queue item for use with the [StatefulIsolate.compute] and
/// [TailoredStatefulIsolate.compute] functions.
@internal
class FutureBackpressureRunConfiguration<R>
    extends BackpressureRunConfiguration<R> {
  /// Internal handle for completing the job.
  @internal
  final Completer<R> completer;

  /// Creates a job queue item for a [Future] response.
  @internal
  const FutureBackpressureRunConfiguration(this.completer, super.configuration);

  @override
  void closeError(Object error, [StackTrace? stackTrace]) {
    completer.completeError(error, stackTrace);
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

/// Job queue item for use with the [StatefulIsolate.stream] and
/// [TailoredStatefulIsolate.computeStream] functions.
@internal
class StreamBackpressureConfiguration<R>
    extends BackpressureRunConfiguration<R> {
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

@internal
class TailoredFutureBackpressureConfiguration<Q, R>
    extends TailoredBackpressureConfiguration<Q, R> {
  /// Internal handle for sending stream events to the listener.
  @internal
  final Completer<R> completer;

  /// Creates a job queue item for a [Stream] response.
  @internal
  const TailoredFutureBackpressureConfiguration(
    this.completer,
    super.configuration,
  );

  @override
  TailoredBackpressureConfiguration<Q, R> copyWith(
    TailoredIsolateConfiguration<Q, R> isolateConfiguration,
  ) {
    return TailoredFutureBackpressureConfiguration(
      completer,
      isolateConfiguration,
    );
  }

  @override
  void closeError(Object error, [StackTrace? stackTrace]) {
    completer.completeError(error, stackTrace);
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

@internal
class TailoredStreamBackpressureConfiguration<Q, R>
    extends TailoredBackpressureConfiguration<Q, R> {
  /// Internal handle for sending stream events to the listener.
  @internal
  final StreamController<R> streamController;

  /// Creates a job queue item for a [Stream] response.
  @internal
  const TailoredStreamBackpressureConfiguration(
    this.streamController,
    super.configuration,
  );

  @override
  void closeError(Object error, [StackTrace? stackTrace]) {
    streamController.addError(error, stackTrace);
    streamController.close();
  }

  @override
  TailoredBackpressureConfiguration<Q, R> copyWith(
    TailoredIsolateConfiguration<Q, R> isolateConfiguration,
  ) {
    return TailoredStreamBackpressureConfiguration(
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

abstract class BaseBackpressureStrategy<R> {
  /// Function that returns true if the back pressure strategy has a job in
  /// queue.
  bool hasNext();

  /// Function that returns the next job in queue.
  ///
  /// Always check [hasNext] before running this function, as this function
  /// has no guarantee that it will not throw exception if no items are in
  /// queue.
  BackpressureConfiguration<R> takeNext();

  /// Adds another job to the queue.
  void add(covariant BackpressureConfiguration<R> configuration);

  /// Drops the job item, completing it with an error.
  void drop(covariant BackpressureConfiguration configuration) {
    configuration.closeError(const BackpressureDropException());
  }

  /// Clears the queue and cleans up.
  ///
  /// Implementing this function, remember to [drop] all jobs in queue so all
  /// jobs will complete with at least a failure.
  void dispose();
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
abstract class BackpressureStrategy<R> extends BaseBackpressureStrategy<R> {}

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
abstract class TailoredBackpressureStrategy<Q, R>
    extends BaseBackpressureStrategy<R> {
  /// Function that returns the next job in queue.
  ///
  /// Always check [hasNext] before running this function, as this function
  /// has no guarantee that it will not throw exception if no items are in
  /// queue.
  @override
  TailoredBackpressureConfiguration<Q, R> takeNext();

  /// Adds another job to the queue.
  @override
  void add(TailoredBackpressureConfiguration<Q, R> configuration);

  /// Drops the job item, completing it with an error.
  @override
  void drop(TailoredBackpressureConfiguration configuration) {
    configuration.closeError(const BackpressureDropException());
  }
}
