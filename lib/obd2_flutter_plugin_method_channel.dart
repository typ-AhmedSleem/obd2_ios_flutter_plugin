import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'obd2_flutter_plugin_constants.dart';
import 'obd2_flutter_plugin_platform_interface.dart';

class MethodChannelObd2FlutterPlugin extends Obd2FlutterPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel(METHOD_CHANNEL_NAME);

  @override
  Future<int?> getFuelLevel() async {
    return await methodChannel.invokeMethod<int?>(GET_FUEL_LEVEL_METHOD_NAME);
  }
}
