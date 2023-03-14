/// Base exception that is thrown when job is dropped.
abstract class DropException implements Exception {}

/// Exception that is thrown when a job is dropped due to backpressure.
class BackpressureDropException extends DropException {}

/// Exception that is thrown when a job is dropped due to isolate being closed.
class IsolateClosedDropException extends DropException {}
