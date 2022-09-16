The power of [integral_isolates](https://pub.dev/packages/use_isolate) neatly packed up in a [hook](https://pub.dev/packages/flutter_hooks).

## Usage

Using an isolate in a hook has never been simpler. With the use of `useIsolate()` we you can get a compute function similar to [compute](https://api.flutter.dev/flutter/foundation/compute-constant.html) but that lives longer. You don't have to care about lifecycle, the hook handles that for you.

Example:
``` dart
class TestingIsolateHook extends HookWidget {
  const TestingIsolateHook({super.key});

  @override
  Widget build(BuildContext context) {
    final isolate = useIsolate();
    final number = useState(1);

    return TextButton(
      onPressed: () async {
        var isPrime = await isolate(_isPrime, number.value);
        print('${number.value} is a prime number? ${isPrime}');
        number.value += 1;
      },
      child: Text(
        'Check if ${number.value} is a prime number',
      ),
    );
  }

  static bool _isPrime(int value) {
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
}
```

Just as integral_isolates, this hook supports backpressure strategies, just send a strategy in as parameter:
```dart
useIsolate(backpressureStrategy: DiscardNewBackPressureStrategy());
```

## Additional information

You could expect this API to be _mostly_ stable, but implementation of the underlying package (integral_isolates) is not fully finalized yet, and there is more features coming before both packages can count as stable.
