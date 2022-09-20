/// Exception that is thrown if init has not been called before starting to use
/// isolate.
class InitException implements Exception {
  @override
  String toString() {
    return 'You need to call init before starting to use the isolate';
  }
}
