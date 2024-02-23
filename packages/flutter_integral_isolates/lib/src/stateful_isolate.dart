import 'package:flutter/services.dart';
import 'package:integral_isolates/integral_isolates.dart' as integral_isolate;

class StatefulIsolate extends integral_isolate.StatefulIsolate {
  @override
  integral_isolate.InitThingie<Object> postInit() {
    final rootIsolateToken = RootIsolateToken.instance!;
    return integral_isolate.InitThingie(
      _initPluginForIsolate,
      rootIsolateToken,
    );
  }

  // TODO(lohnn): Before release - figure out how we can make this typed
  static void _initPluginForIsolate(dynamic rootIsolateToken) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(
      rootIsolateToken as RootIsolateToken,
    );
  }
}
