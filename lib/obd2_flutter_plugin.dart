
import 'obd2_flutter_plugin_platform_interface.dart';

class Obd2FlutterPlugin {
  Future<String?> getPlatformVersion() {
    return Obd2FlutterPluginPlatform.instance.getPlatformVersion();
  }
}
