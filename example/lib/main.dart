import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:obd2_flutter_plugin/obd2_flutter_plugin.dart';
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
  String _fuelLevel = "--";
  final _obd2FlutterPlugin = Obd2FlutterPlugin();
  final logger = Logger("MyApp");

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    //* Get bounded bluetooth devices
    List<String> devices;
    try {
      devices = await _obd2FlutterPlugin.getBluetoothDevices() ?? List.empty();
      logger.log("Got devices: $devices");
    } on PlatformException {
      logger.log("Error getting bluetooth devices");
      return;
    }

    // todo: Connect to target device

    // todo: Init the target device

    //* Fuel level
    String fuelLevel;
    try {
      fuelLevel = await _obd2FlutterPlugin.getFuelLevel() ?? "-1";
    } on PlatformException {
      fuelLevel = "UNKNOWN";
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _fuelLevel = fuelLevel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_fuelLevel\n'),
        ),
      ),
    );
  }
}
