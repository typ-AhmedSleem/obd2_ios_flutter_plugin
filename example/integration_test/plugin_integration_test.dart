// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://docs.flutter.dev/cookbook/testing/integration/introduction

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:obd2_flutter_plugin/obd2_flutter_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final Obd2FlutterPlugin plugin = Obd2FlutterPlugin();
    final int carFuelLevel = await plugin.getFuelLevel() ?? -1;
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(carFuelLevel, true);
  });
}