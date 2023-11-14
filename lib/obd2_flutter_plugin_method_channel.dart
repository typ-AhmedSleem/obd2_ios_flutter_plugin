import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'obd2_flutter_plugin_constants.dart';
import 'obd2_flutter_plugin_platform_interface.dart';

class MethodChannelObd2FlutterPlugin extends Obd2FlutterPluginPlatform {
  @visibleForTesting
  final bleChannel = const MethodChannel(FUEL_CHANNEL);

  @visibleForTesting
  final fuelChannel = const MethodChannel(BLUE_DEVICES_CHANNEL);

  @override
  Future<List<String>?> getBLEDevices() async {
    return await bleChannel
        .invokeMethod<List<String>?>(SCAN_BLE_DEVICES_METHOD_NAME);
  }

  @override
  Future<bool?> connect(String address) async {
    return await fuelChannel.invokeMethod<bool?>(CONNECT_OBD_METHOD_NAME);
  }

  @override
  Future<void> init() async {
    return await fuelChannel.invokeMethod<void>(INIT_OBD_METHOD_NAME);
  }

  @override
  Future<String?> getFuelLevel() async {
    return await fuelChannel.invokeMethod<String?>(GET_FUEL_LEVEL_METHOD_NAME);
  }
}
