import Flutter
import UIKit

public class Obd2FlutterPlugin: NSObject, FlutterPlugin {

  @ObservedObject private var obd2 = OBD2()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: Constants.METHOD_CHANNEL_NAME, binaryMessenger: registrar.messenger())
    let instance = Obd2FlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case Constants.GET_FUEL_LEVEL_METHOD_NAME:
      result(self.getCarFuelLevel())

    case Constants.CONNECT_OBD_METHOD_NAME:
        // todo: Check Bluetooth.
        // todo: Connect to OBD2.
        // todo: Get Peripherals of OBD2 to start communication.
      result(FlutterMethodNotImplemented)
    case Constants.INIT_OBD2_METHOD_NAME:
      // todo: Send (init) commands sequence in-order to initialize the OBD
      // todo: Return the result code and tunnel it back to Flutter to update UI
      result(FlutterMethodNotImplemented)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func connectOBD() -> Bool {
    // todo: Code this method to check for Bluetooth stuff like (Permission, Enable and Hardware)
    return false
  }

  private func initOBD() -> Bool {
    // todo: Send the sequence of INIT commands to the OBD adapter
    return false
  }

  private func sendCommand(command: ODBCommand) -> Void {
  }

  private func getCarFuelLevel() -> Int {
    // todo: Send ACK command to OBD2.
    // todo: Send GetFuelLevel command to OBD2.
    // todo: Wait for the result from OBD2.
    var carFuelLevel = self.INITIAL_RESULT
    
    return carFuelLevel
  } 

}
