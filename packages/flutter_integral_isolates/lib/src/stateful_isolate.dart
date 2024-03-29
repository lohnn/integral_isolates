import 'package:flutter/services.dart';
import 'package:integral_isolates/integral_isolates.dart' as integral_isolate;

class StatefulIsolate extends integral_isolate.StatefulIsolate
    implements integral_isolate.PostInitStuff<RootIsolateToken> {
  StatefulIsolate({
    super.backpressureStrategy,
    super.autoInit,
  });

  @override
  integral_isolate.InitThingie<RootIsolateToken> postInit() {
    final rootIsolateToken = RootIsolateToken.instance!;
    return integral_isolate.InitThingie<RootIsolateToken>(
      _initPluginForIsolate,
      rootIsolateToken,
    );
  }

  // TODO(lohnn): Before release - figure out how we can make this typed
  static void _initPluginForIsolate(RootIsolateToken rootIsolateToken) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(
      rootIsolateToken,
    );
  }
}
