import 'dart:ffi';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'obd2_flutter_plugin_method_channel.dart';

abstract class Obd2FlutterPluginPlatform extends PlatformInterface {
  /// Constructs a Obd2FlutterPluginPlatform.
  Obd2FlutterPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static Obd2FlutterPluginPlatform _instance = MethodChannelObd2FlutterPlugin();

  /// The default instance of [Obd2FlutterPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelObd2FlutterPlugin].
  static Obd2FlutterPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [Obd2FlutterPluginPlatform] when
  /// they register themselves.
  static set instance(Obd2FlutterPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<List<String>?> getBLEDevices() {
    throw UnimplementedError(
        "getBLEDevices() should be overridden not called from base interface");
  }

  Future<bool?> connect(String address) {
    throw UnimplementedError(
        "connect() should be overridden not called from base interface");
  }

  Future<void> init() {
    throw UnimplementedError(
        "init() should be overridden not called from base interface");
  }

  /// Calls the native ios code that gets the car fuel level through
  /// OBD2 bluetooth connection.
  Future<String?> getFuelLevel() {
    throw UnimplementedError(
        "getFuelLevel() should be overridden not called from base interface");
  }
}
