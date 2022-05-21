library use_isolate;

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:async/async.dart';
import 'package:integral_isolates/src/backpressure/discard_new_backpressure.dart';
import 'package:integral_isolates/src/compute_callback.dart';
import 'package:integral_isolates/src/isolate_configuration.dart';
import 'package:meta/meta.dart';

abstract class IsolateState {
  late StreamQueue _isolateToMainPort;
  final _mainToIsolatePort = Completer<SendPort>();
  final _closePort = Completer<SendPort>();

  Future init() async {
    final isolateToMainPort = ReceivePort();
    _isolateToMainPort = StreamQueue(isolateToMainPort);
    await Isolate.spawn(
      _isolate,
      isolateToMainPort.sendPort,
    );

    _isolateToMainPort = _isolateToMainPort;

    final isolateSetupResponse =
        await _isolateToMainPort.next as _IsolateSetupResponse;
    _mainToIsolatePort.complete(isolateSetupResponse.mainToIsolatePort);
    _closePort.complete(isolateSetupResponse.closePort);

    _handleIsolateCalls(isolateSetupResponse.mainToIsolatePort);
  }

  Future _handleIsolateCalls(SendPort mainToIsolate) async {
    await for (final configuration in _backpressure.stream()) {
      mainToIsolate.send(configuration.value);
      log('Picking next value');
      final response = await _isolateToMainPort.next;

      if (response is _SuccessIsolateResponse) {
        configuration.key.complete(response.response);
      } else if (response is _ErrorIsolateResponse) {
        configuration.key.completeError(
          response.error,
          response.stackTrace,
        );
      } else {
        // TODO(lohnn): Should not be possible? Notify the developer of issue?
      }
    }
    log('Listener now closed');
  }

  final _backpressure = DiscardNewBackPressure();

  Future<R> isolate<Q, R>(
    ComputeCallback<Q, R> callback,
    Q message, {
    String? debugLabel,
  }) {
    debugLabel ??= 'compute';

    final Flow flow = Flow.begin();

    final completer = Completer<R>();
    final isolateConfiguration = IsolateConfiguration(
      callback,
      message,
      debugLabel,
      flow.id,
    );

    _backpressure.add(MapEntry(completer, isolateConfiguration));
    return completer.future;
  }

  Future dispose() async {
    (await _closePort.future).send('close');
    _isolateToMainPort.cancel();
    // _isolateToMainPort.close();

    _backpressure.dispose();
  }
}

Future _isolate(SendPort isolateToMainPort) async {
  final mainToIsolateStream = ReceivePort();
  final closePort = ReceivePort();

  isolateToMainPort.send(
    _IsolateSetupResponse(
      mainToIsolateStream.sendPort,
      closePort.sendPort,
    ),
  );

  closePort.first.then((_) {
    log('Closing shop');
    mainToIsolateStream.close();
    closePort.close();
  });

// TODO(lohnn): Use listen to not run in queue?
  await for (final data in mainToIsolateStream) {
    try {
      if (data is IsolateConfiguration) {
        try {
          log('${data.flowId}: Trying to calculate data and stuff?');
          isolateToMainPort.send(
            _IsolateResponse.success(
              data.flowId,
              await data.applyAndTime(),
            ),
          );
        } catch (error, stackTrace) {
          log('${data.flowId}: Failed to calculate data and stuff');
          isolateToMainPort.send(
            _IsolateResponse.error(data.flowId, error, stackTrace),
          );
        }
      } else {
        isolateToMainPort.send(null);
      }
    } catch (_) {
      isolateToMainPort.send(null);
    }
  }
  log('Now closed, bye');
}

typedef ComputeImpl = Future<R> Function<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message, {
  String? debugLabel,
});

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
      _SuccessIsolateResponse;

  const factory _IsolateResponse.error(
    int flowId,
    Object error,
    StackTrace stackTrace,
  ) = _ErrorIsolateResponse;
}

class _SuccessIsolateResponse<R> extends _IsolateResponse<R> {
  final R response;

  const _SuccessIsolateResponse(super.flowId, this.response);
}

class _ErrorIsolateResponse<R> extends _IsolateResponse<R> {
  final Object error;
  final StackTrace stackTrace;

  const _ErrorIsolateResponse(super.flowId, this.error, this.stackTrace);
}
