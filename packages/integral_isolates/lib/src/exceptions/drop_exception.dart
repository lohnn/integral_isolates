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
    return 'Exception: This is an unexpected internal error that should not not'
        ' have been possible. Please file an issue at '
        'https://github.com/lohnn/integral_isolates/issues with a reproducible '
        'example.';
  }
}
