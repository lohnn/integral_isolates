library use_isolate;

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:meta/meta.dart';

abstract class IsolateState {
  late ReceivePort isolateToMainPort;
  final mainToIsolatePort = Completer<SendPort>();
  final closePort = Completer<SendPort>();

  final Map<int, Completer> _queue = {};

  Future init() async {
    isolateToMainPort = ReceivePort();
    await Isolate.spawn(
      _isolate,
      isolateToMainPort.sendPort,
    );

    isolateToMainPort = isolateToMainPort
      ..listen((data) {
        if (data is _IsolateSetupResponse) {
          mainToIsolatePort.complete(data.mainToIsolatePort);
          closePort.complete(data.closePort);
        } else {
          if (data is _SuccessIsolateRespnose) {
            //TODO: Handle response error
            _queue.remove(data.flowId)?.complete(data.response);
          } else if (data is _ErrorIsolateResponse) {
            _queue.remove(data.flowId)?.completeError(
                  data.error,
                  data.stackTrace,
                );
          }
        }
      });
  }

  Future<R> isolate<Q, R>(ComputeCallback<Q, R> callback, Q message,
      {String? debugLabel}) async {
    debugLabel ??= 'compute';

    final Flow flow = Flow.begin();
    final mainToIsolate = await mainToIsolatePort.future;

    mainToIsolate.send(
      _IsolateConfiguration(
        callback,
        message,
        debugLabel,
        flow.id,
      ),
    );

    final completer = Completer<R>();
    _queue[flow.id] = completer;
    return completer.future;
  }

  Future dispose() async {
    (await closePort.future).send("close");
    isolateToMainPort.close();

    for (final entry in _queue.entries) {
      entry.value.completeError("Isolate closed");
    }
  }

  static Future _isolate(SendPort isolateToMainPort) async {
    final mainToIsolateStream = ReceivePort();
    final closePort = ReceivePort();

    isolateToMainPort.send(_IsolateSetupResponse(
      mainToIsolateStream.sendPort,
      closePort.sendPort,
    ));

    closePort.first.then((_) {
      print("Closing shop");
      mainToIsolateStream.close();
      closePort.close();
    });

    //TODO: Use listen to not run in queue?
    await for (final data in mainToIsolateStream) {
      try {
        if (data is _IsolateConfiguration) {
          try {
            print("${data.flowId}: Trying to calculate data and stuff?");
            //TODO: Run and return result
            isolateToMainPort.send(
              _IsolateResponse.success(
                data.flowId,
                await data.applyAndTime(),
              ),
            );
          } catch (error, stackTrace) {
            //TODO: Return error
            print("${data.flowId}: Failed to calculate data and stuff");
            isolateToMainPort.send(
              _IsolateResponse.error(data.flowId, error, stackTrace),
            );
            // isolateToMainStream.send(null);
          }
          // } else if (data is String && data == "close") {
          //   mainToIsolateStream.close();
        } else {
          isolateToMainPort.send(null);
        }
      } catch (_) {
        isolateToMainPort.send(null);
      }
    }
  }
}

typedef ComputeImpl = Future<R> Function<Q, R>(
    ComputeCallback<Q, R> callback, Q message,
    {String? debugLabel});

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);

class Temp {
  Future<R> compute<Q, R>(
    ComputeCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) async {
    throw Exception();
  }
}

@immutable
class _IsolateSetupResponse {
  const _IsolateSetupResponse(this.mainToIsolatePort, this.closePort);

  final SendPort mainToIsolatePort;
  final SendPort closePort;
}

abstract class _IsolateResponse<R> {
  final int flowId;

  const _IsolateResponse(this.flowId);

  const factory _IsolateResponse.success(int flowId, R response) =
      _SuccessIsolateRespnose;

  const factory _IsolateResponse.error(
      int flowId, Object error, StackTrace stackTrace) = _ErrorIsolateResponse;
}

class _SuccessIsolateRespnose<R> extends _IsolateResponse<R> {
  final R response;

  const _SuccessIsolateRespnose(super.flowId, this.response);
}

class _ErrorIsolateResponse<R> extends _IsolateResponse<R> {
  final Object error;
  final StackTrace stackTrace;

  const _ErrorIsolateResponse(super.flowId, this.error, this.stackTrace);
}

@immutable
class _IsolateConfiguration<Q, R> {
  const _IsolateConfiguration(
    this.callback,
    this.message,
    this.debugLabel,
    this.flowId,
  );

  final ComputeCallback<Q, R> callback;
  final Q message;
  final String debugLabel;
  final int flowId;

  FutureOr<R> applyAndTime() {
    return Timeline.timeSync(
      debugLabel,
      () => callback(message),
      flow: Flow.step(flowId),
    );
  }
}
