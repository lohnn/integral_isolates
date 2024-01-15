<img src="https://github.com/lohnn/integral_isolates/blob/main/packages/integral_isolates/resources/icon.png?raw=true" width="200" alt="Integral Isolates" />

Easy to use isolates for Dart and Flutter.

## Usage

Almost as easy to use as Dart's built-in [compute](https://api.flutter.dev/flutter/foundation/compute.html) function,
but using a long-lived isolate.

Example:

```dart
void main() async {
  final statefulIsolate = StatefulIsolate();
  print(await statefulIsolate.compute(_isPrime, 7));
  print(await statefulIsolate.compute(_isPrime, 42));
  statefulIsolate.dispose();
}

bool _isPrime(int value) {
  if (value == 1) {
    return false;
  }
  for (int i = 2; i < value; ++i) {
    if (value % i == 0) {
      return false;
    }
  }
  return true;
}
```

Remember to always dispose once you are done using the isolate to clean up and close the isolate:
```dart
statefulIsolate.dispose();
```

#### Specialized/tailored isolates

If you know the input and output types for the stateful isolate at creation time you can use a
`TailoredStatefulIsolate`. They work the exact same way as the `StatefulIsolate`, but declares at creation time what
types are supported as input and output of the compute functions.

Example:
```dart
void main() async {
  // This isolate only takes `int` as input and returns `bool`.
  final statefulIsolate = TailoredStatefulIsolate<int, bool>();
  print(await statefulIsolate.compute(_isPrime, 7));
  print(await statefulIsolate.compute(_isPrime, 42));
  statefulIsolate.dispose();
}
```

#### Handling backpressure

If you hammer the stateful isolate with too many calls that takes too long to run, your memory will eventually run out
as the compute call stack keeps growing. A way to handle that is to set a backpressure strategy when creating the
isolate.

There are a few different backpressure strategies supported out of the box. To use them just declare which one to use
when creating the stateful isolate:
```dart
final isolate = StatefulIsolate(backpressureStrategy: DiscardNewBackPressureStrategy());
```

Currently supported strategies can be found in the
[documentation](https://pub.dev/documentation/integral_isolates/latest/integral_isolates/BackpressureStrategy-class.html).

## Additional information

The API of this package is not final, and is subject to change.

### Breaking change

* `integral_isolates` v0.5.0: Renamed compute functions to `isolate.compute(..)` and `isolate.computeStream(..)`.
* `integral_isolates` v0.4.0: deprecated the class `Isolated` in favor of `StatefulIsolate`. The class
`TailoredStatefulIsolate` was also added, adding support for an isolate that allows for specifying input and output
types.

### Are you using flutter_hooks?

Try the [use_isolate](https://pub.dev/packages/use_isolate) package that controls the lifecycle of the isolate, so you don't have to.
