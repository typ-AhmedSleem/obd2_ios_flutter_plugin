import Flutter
import UIKit

public class Obd2FlutterPlugin: NSObject, FlutterPlugin {

  private var obd2 = OBD2()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let bluetoothChannel = FlutterMethodChannel(name: MethodChannelsNames.BLUE_DEVICES, binaryMessenger: registrar.messenger())
    let fuelChannel = FlutterMethodChannel(name: MethodChannelsNames.FUEL, binaryMessenger: registrar.messenger())
    let instance = Obd2FlutterPlugin()
    registrar.addMethodCallDelegate(instance, channel: bluetoothChannel)
    registrar.addMethodCallDelegate(instance, channel: fuelChannel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
      case MethodsNames.SCAN_BLUETOOTH_DEVICES:
        if self.obd2.isBLEManagerInitialized {
          do {
            let devices: [String] = await obd2.bluetoothManager.retrieveBoundedBluetoothDevicesSerialized()
            result(devices)
          } catch {
            let emptyDevicesList: [String] = [] 
            result(emptyDevicesList)
          }
        }
        //* If we reached this point, it means that BLE manager hasn't yet been initialized. So, result an error
        result(FlutterError(
          code: "400",
          message: "BluetoothManager either poweredOff or hasn't yet been initialized yet. Check it in your settings.",
          details: nil
        ))
      case MethodsNames.CONNECT_ADAPTER:
        do {
          //? Flutter will send me device address in args
          let address = call.arguments as String? else { throw CantConnectError() }
          let connected = await self.obd2.connect(target: address)
          result(connected)
        } catch {
            result(FlutterError(
              code: "400",
              message: "Can't connect to device. Please try again",
              details: nil
            ))
        }
      case MethodsNames.INIT_ADAPTER:
        do {
          await self.obd2.initializeOBD()
          //* This method result nothing and idk why :)
        } catch {
          result(FlutterError(
            code: "400",
            message: "Can't initialize the OBD adapter. Check if it's connected or it may be out-of-range",
            details: nil
          ))
        }
      case MethodsNames.GET_FUEL_LEVEL:
        do {
          let fuelLevel = await obd2.executeCommand(command: FuelLevelCommand(delay: 100), expectResponse: true)
          result(fuelLevel)
        } catch {
          result(-1)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
  }

}
