import 'dart:io';

import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:use_isolate/use_isolate.dart';

void main() {
  runApp(const MaterialApp(home: OuterWidget()));
}

class OuterWidget extends HookWidget {
  const OuterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTesting = useState<bool>(false);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          child: const Text('Plugin example app'),
          onTap: () {
            isTesting.value = !isTesting.value;
          },
        ),
      ),
      body: isTesting.value
          ? const IsolateTestingWidget()
          : const Center(child: Text("Not currently testing")),
    );
  }
}

class IsolateTestingWidget extends HookWidget {
  const IsolateTestingWidget({super.key});

  static String _hello(_MethodInput input) {
    sleep(input.delay);
    return input.text;
  }

  static void _init(RootIsolateToken rootIsolateToken) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    print('I am init!');
  }

  static void _native(Object? _) {
    final dir = LocalFileSystem().directory(
      '/Users/lohnn/Programming/integral_isolates',
    );
    print(dir.listSync());
  }

  static String _error(_MethodInput input) {
    sleep(input.delay);
    throw Exception('error');
  }

  @override
  Widget build(BuildContext context) {
    final isolate = useIsolate();
    final tailoredIsolate = useTailoredIsolate<_MethodInput, String>(
      backpressureStrategy: CombineBackPressureStrategy(
        (oldData, newData) {
          return _MethodInput(oldData.text + newData.text);
        },
      ),
    );

    Future<String?> safeHello(_MethodInput input) async {
      try {
        return await tailoredIsolate(_hello, input);
      } catch (e) {
        return null;
      }
    }

    return ListView(
      children: [
        TextButton(
          onPressed: () async {
            final rootIsolateToken = RootIsolateToken.instance!;
            await isolate(_init, rootIsolateToken);
          },
          child: const Text('Init BackgroundIsolateBinaryMessenger'),
        ),
        TextButton(
          onPressed: () async {
            await isolate(
              _native,
              null,
            );
          },
          child: const Text('Run plugin in Isolate'),
        ),
        TextButton(
          onPressed: () async {
            final hi = await compute(_hello, _MethodInput("hi"));
            print(hi);
          },
          child: const Text('Run compute'),
        ),
        TextButton(
          onPressed: () async {
            final hi =
                _hello(_MethodInput("hi", delay: const Duration(seconds: 2)));
            print(hi);
          },
          child: const Text('Jank'),
        ),
        TextButton(
          onPressed: () async {
            final hi = await isolate(
                _hello, _MethodInput("hi", delay: const Duration(seconds: 2)));
            print(hi);
          },
          child: const Text('Run one'),
        ),
        TextButton(
          onPressed: () async {
            final yo = await isolate(_hello, _MethodInput("yo"));
            print(yo);
          },
          child: const Text('Run other'),
        ),
        TextButton(
          onPressed: () async {
            final hi = await isolate(_hello, _MethodInput("hi"));
            print(hi);
            final yo = await isolate(_hello, _MethodInput("yo"));
            print(yo);
          },
          child: const Text('Run two in queue'),
        ),
        TextButton(
          onPressed: () async {
            isolate(_hello, _MethodInput("hi")).then(print);
            isolate(
              _hello,
              _MethodInput(
                "yo",
                delay: const Duration(milliseconds: 500),
              ),
            ).then(print);
          },
          child: const Text('Run two in parallel, listen to value'),
        ),
        TextButton(
          onPressed: () async {
            final responses = await Future.wait(
              [
                isolate(_hello, _MethodInput("hi")),
                isolate(
                  _hello,
                  _MethodInput("ho", delay: const Duration(milliseconds: 500)),
                ),
              ],
            );
            print(responses);
          },
          child: const Text('Two in parallel with future wait'),
        ),
        TextButton(
          onPressed: () async {
            final responses = await Future.wait(
              [
                safeHello(_MethodInput("hi")),
                safeHello(
                  _MethodInput("ho", delay: const Duration(milliseconds: 500)),
                ),
                safeHello(_MethodInput("hi")),
                safeHello(_MethodInput("hi")),
              ],
            );
            print(responses);
          },
          child: const Text('Tailored isolate'),
        ),
        TextButton(
          onPressed: () async {
            final hi = await isolate(_error, _MethodInput("hi"));
            print(hi);
          },
          child: const Text('Error'),
        ),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _MethodInput {
  final String text;
  final Duration delay;

  _MethodInput(
    this.text, {
    this.delay = const Duration(seconds: 1),
  });
}
