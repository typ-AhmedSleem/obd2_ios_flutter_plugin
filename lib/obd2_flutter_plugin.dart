import 'obd2_flutter_plugin_platform_interface.dart';

class Obd2FlutterPlugin {
  Future<List<String>?> getBluetoothDevices() {
    return Obd2FlutterPluginPlatform.instance.getBLEDevices();
  }

  Future<bool?> connect(String address) {
    return Obd2FlutterPluginPlatform.instance.connect(address);
  }

  Future<void> init() {
    return Obd2FlutterPluginPlatform.instance.init();
  }

  Future<String?> getFuelLevel() {
    return Obd2FlutterPluginPlatform.instance.getFuelLevel();
  }
}
