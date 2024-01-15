<div style="text-align: center;">
    <img src="https://github.com/lohnn/integral_isolates/blob/main/packages/integral_isolates/resources/icon.png?raw=true" width="200" alt="Integral Isolates" />
    <p>Easy to use isolates for Dart and Flutter.</p>
    <a title="Pub" href="https://pub.dev/packages/integral_isolates"><img src="https://img.shields.io/pub/v/integral_isolates.svg?style=popout"/></a>
    <a title="Test" href="https://github.com/lohnn/integral_isolates/actions?query=workflow%3Acicd+branch%3Amain"><img src="https://github.com/lohnn/integral_isolates/workflows/cicd/badge.svg?branch=main&event=push"/></a>
    <a title="Melos" href="https://github.com/invertase/melos"><img src="https://img.shields.io/badge/maintained%20with-melos-f700ff.svg"/></a>
</div>



## Usage

Almost as easy to use as [compute](https://api.flutter.dev/flutter/foundation/compute.html), but using a long-lived
isolate. For example:

```dart
void main() async {
  final statefulIsolate = StatefulIsolate();
  print(await statefulIsolate.isolate(_isPrime, 7));
  print(await statefulIsolate.isolate(_isPrime, 42));
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

Remember to always dispose once you are done using the isolate to clean up and close the isolate.
```dart
statefulIsolate.dispose();
```

Different backpressure strategies are also supported by just sending in the desired strategy:
```dart
StatefulIsolate(backpressureStrategy: DiscardNewBackPressureStrategy());
```

Currently supported strategies can be found in the
[documentation](https://pub.dev/documentation/integral_isolates/latest/integral_isolates/BackpressureStrategy-class.html).


## Additional information

The API of this package is not final, and is subject to change.

### Breaking change
* `integral_isolates` v0.5.0: the package now uses Dart 3.
* `integral_isolates` v0.4.0: deprecated the class `Isolated` in favor of `StatefulIsolate`. The class
`TailoredStatefulIsolate` was also added, adding support for an isolate that allows for specifying input and output
types.

### Are you using hooks?

Try the [use_isolate](https://pub.dev/packages/use_isolate) package that controls the lifecycle of
the isolate, so you don't have to.
