import 'package:flutter_test/flutter_test.dart';
import 'package:obd2_flutter_plugin/obd2_flutter_plugin.dart';
import 'package:obd2_flutter_plugin/obd2_flutter_plugin_platform_interface.dart';
import 'package:obd2_flutter_plugin/obd2_flutter_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockObd2FlutterPluginPlatform
    with MockPlatformInterfaceMixin
    implements Obd2FlutterPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final Obd2FlutterPluginPlatform initialPlatform = Obd2FlutterPluginPlatform.instance;

  test('$MethodChannelObd2FlutterPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelObd2FlutterPlugin>());
  });

  test('getPlatformVersion', () async {
    Obd2FlutterPlugin obd2FlutterPlugin = Obd2FlutterPlugin();
    MockObd2FlutterPluginPlatform fakePlatform = MockObd2FlutterPluginPlatform();
    Obd2FlutterPluginPlatform.instance = fakePlatform;

    expect(await obd2FlutterPlugin.getPlatformVersion(), '42');
  });
}
