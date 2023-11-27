import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:obd2_flutter_plugin/obd2_flutter_plugin.dart';
import 'package:obd2_flutter_plugin/obd2_flutter_plugin_constants.dart';
import 'logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final logger = Logger("MyApp");
  final _obd2FlutterPlugin = Obd2FlutterPlugin();

  Iterable<BluetoothDevice> _bleDevices = [];
  String? _adapterAddress;
  bool _connected = false;
  bool _adapterInitialized = false;
  String _fuelLevel = "--";

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('iOS OBD Plugin sample app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              CupertinoButton(
                onPressed: () async {
                  try {
                    // Resolve received devices
                    var rawDevices = await _obd2FlutterPlugin.getBluetoothDevices();
                    var devices = rawDevices.map<BluetoothDevice>((d) => BluetoothDevice.fromJson(d as String? ?? ""));
                    logger.log("Got: raw=${rawDevices.length} -> resolved=${devices.length} Devices");
                    // Try to find the adapter by its name in the list
                    String? tempAddress;
                    for (var device in devices) {
                      logger.log("Trying device: ${device.name} at ${device.address}");
                      if (device.name == OBD_ADAPTER_NAME) {
                        tempAddress = device.address;
                        logger.log("Found adapter ${device.name} at address ${device.address}");
                        break;
                      }
                    }
                    setState(() {
                      _bleDevices = devices;
                      if (tempAddress != null) _adapterAddress = tempAddress;
                    });
                  } on PlatformException catch (e) {
                    logger.log("Error getting bluetooth devices.\nReason: $e");
                  }
                },
                child: Text(_bleDevices.isNotEmpty ? "Found ${_bleDevices.length} device" : "Scan Bluetooth for devices"),
              ),
              CupertinoButton(
                onPressed: () async {
                  try {
                    final connected = await _obd2FlutterPlugin.connect(_adapterAddress ?? "") ?? false;
                    logger.log(connected ? "Connected to adapter" : "Connect to adapter");
                    setState(() {
                      _connected = connected;
                    });
                  } on PlatformException catch (e) {
                    logger.log("Error connecting to adapter.\nReason: $e");
                  }
                },
                child: Text(_connected
                    ? "Connected to adapter"
                    : _adapterAddress != null
                        ? 'Connect to $_adapterAddress'
                        : "Connect to adapter"),
              ),
              CupertinoButton(
                onPressed: () async {
                  try {
                    await _obd2FlutterPlugin.init();
                    setState(() {
                      _adapterInitialized = true;
                    });
                  } on PlatformException catch (e) {
                    logger.log("Can't initialize adapter..\nReason: $e");
                  }
                },
                child: const Text('Initialize adapter'),
              ),
              CupertinoButton(
                onPressed: () async {
                  try {
                    var fuelLevel = await _obd2FlutterPlugin.getFuelLevel();
                    logger.log("Got fuel level: $fuelLevel");
                    setState(() {
                      _fuelLevel = fuelLevel ?? "Unknown";
                    });
                  } on PlatformException catch (e) {
                    logger.log("Can't get fuel level..\nReason: $e");
                  }
                },
                child: Text(_fuelLevel == "--" ? "Get fuel level" : "FuelLevel: $_fuelLevel"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BluetoothDevice {
  String name;
  String address;

  BluetoothDevice({required this.name, required this.address});

  static BluetoothDevice fromJson(String jsonDevice) {
    final Map<String, String> parsedDevice = json.decode(jsonDevice);
    return BluetoothDevice(name: parsedDevice['name'] ?? "", address: parsedDevice['address'] ?? "");
  }
}
