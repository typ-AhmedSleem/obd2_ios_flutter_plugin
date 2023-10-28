import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'obd2_flutter_plugin_platform_interface.dart';

/// An implementation of [Obd2FlutterPluginPlatform] that uses method channels.
class MethodChannelObd2FlutterPlugin extends Obd2FlutterPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('obd2_flutter_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
