import 'obd2_flutter_plugin_platform_interface.dart';

class Obd2FlutterPlugin {
  Future<int?> getFuelLevel() {
    return Obd2FlutterPluginPlatform.instance.getFuelLevel();
  }

  // Future<Map<String, String>?> connectOBD() {
  //   return Obd2FlutterPluginPlatform.instance.connectOBD();
  // }
}
