import 'package:integral_isolates/src/strings.dart';

/// Base exception that is thrown when job is dropped.
abstract class DropException implements Exception {}

/// Exception that is thrown when a job is dropped due to backpressure.
class BackpressureDropException extends DropException {}

/// Exception that is thrown when a job is dropped due to isolate being closed.
class IsolateClosedDropException extends DropException {}

/// Exception that preferably should never occur, but that will be thrown when
/// the isolate call was dropped in unexpected cases.
class UnexpectedDropException extends DropException {
  @override
  String toString() {
    return 'Exception: $fileBugMessage';
  }
}
