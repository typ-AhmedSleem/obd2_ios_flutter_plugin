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
    
    private func connect(_ address: String, callback: @escaping (Result<Bool, CantConnectError>) -> Void) {
        Task {
            let connected = await self.obd2.connect(target: address)
            callback(.success(connected))
        }
    }
    
    private func initializeOBD(callback: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            await self.obd2.initializeOBD()
            callback(.success(true))
        }
    }
    
    private func getFuelLevel(callback: @escaping (Result<String, ResponseError>) -> Void) {
        Task {
            let fuelLevel = await self.obd2.executeCommand(FuelLevelCommand(delay: 100), expectResponse: true)
            guard let fuelLevel = fuelLevel else {
                callback(.failure(ResponseError(message: "Can't get fuelLevel", matchRegex: false)))
                return
            }
            callback(.success(fuelLevel))
        }
    }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      print("[PLUGIN]: Got call=\(call.method) | args=\(String(describing: call.arguments))")
    switch call.method {
      case MethodsNames.SCAN_BLUETOOTH_DEVICES:
        if self.obd2.isBLEManagerInitialized {
          do {
            let devices: [String] = obd2.bluetoothManager?.retrieveBoundedBluetoothDevicesSerialized() ?? []
              if devices.isEmpty {
                  print("No bounded devices found. Scanning for devices...")
                  self.obd2.bluetoothManager?.scanForDevices()
              } else {
                  print("[PLUGIN]: Retrieved devices= \(devices)")
              }
              result(devices)
          } catch {
            let emptyDevicesList: [String] = []
            print("Can't get BLE devices")
            result(emptyDevicesList)
          }
        } else {
            print("Bluetooth isn't initialized")
            //* If we reached this point, it means that BLE manager hasn't yet been initialized. So, result an error
            result(FlutterError(
              code: "400",
              message: "BluetoothManager either poweredOff or hasn't yet been initialized yet. Check it in your settings.",
              details: nil
            ))
        }
        
      case MethodsNames.CONNECT_ADAPTER:
        do {
          //? Flutter will send me device address in args
            let address = call.arguments as? String
            guard let address = address else { throw CantConnectError() }
            
            self.connect(address) { res in
                switch res {
                case .success(let connected):
                    print(connected ? "Connected" : "Not connected")
                    result(connected)
                case .failure(let error):
                    print(error)
                    result(FlutterError())
                }
            }
        } catch {
            result(FlutterError(
              code: "400",
              message: "Can't connect to device. Please try again",
              details: nil
            ))
        }
      case MethodsNames.INIT_ADAPTER:
        //* This method result nothing and idk why :)
        do {
            self.initializeOBD() { res in
                switch res {
                case .success(let initialized):
                    print("Initialized")
                    result(initialized)
                case .failure(let error):
                    print(error)
                    result(FlutterError(
                        code: "400",
                        message: "Can't initialize adapter",
                        details: nil))
                }
            }
          
        } catch {
          result(FlutterError(
            code: "400",
            message: "Can't initialize the OBD adapter. Check if it's connected or it may be out-of-range",
            details: nil
          ))
        }
      case MethodsNames.GET_FUEL_LEVEL:
        do {
            self.getFuelLevel() { res in
                switch res {
                case .success(let fuelLevel):
                    print("Got fuel level: \(fuelLevel)")
                    result(fuelLevel)
                case .failure(let error):
                    print("Error getting fuelLevel: \(error.message)")
                    result("UNKNOWN")
                }
            }
        } catch {
          result("UNKNOWN")
        }
      default:
        result(FlutterMethodNotImplemented)
      }
  }

}
