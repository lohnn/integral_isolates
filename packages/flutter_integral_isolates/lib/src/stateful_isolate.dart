import 'package:flutter/services.dart';
import 'package:integral_isolates/integral_isolates.dart' as integral_isolate;

class StatefulIsolate extends integral_isolate.StatefulIsolate {
  @override
  integral_isolate.InitThingie<RootIsolateToken> postInit() {
    final rootIsolateToken = RootIsolateToken.instance!;
    return integral_isolate.InitThingie<RootIsolateToken>(
      _initPluginForIsolate,
      rootIsolateToken,
    );
  }

  void _initPluginForIsolate(RootIsolateToken rootIsolateToken) {
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  }
}
