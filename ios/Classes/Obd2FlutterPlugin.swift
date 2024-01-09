import Flutter
import UIKit

public class Obd2FlutterPlugin: NSObject, FlutterPlugin {
    
    private let obd2 = OBD2()
    private let logger = Logger("OBD2Plugin")
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Define method channels
        let bluetoothChannel = FlutterMethodChannel(name: MethodChannelsNames.BLUE_DEVICES, binaryMessenger: registrar.messenger())
        let fuelChannel = FlutterMethodChannel(name: MethodChannelsNames.FUEL, binaryMessenger: registrar.messenger())
        // Create a new instance of Obd2FlutterPlugin
        let instance = Obd2FlutterPlugin()
        // Register method channels to plugin registrar
        registrar.addMethodCallDelegate(instance, channel: bluetoothChannel)
        registrar.addMethodCallDelegate(instance, channel: fuelChannel)
    }
    
    private func performBluetoothScan(callback: @escaping (Result<[String], Error>) -> Void) {
        Task {
            do {
                try await self.obd2.bluetoothManager.scanForDevices()
                let devices = obd2.bluetoothManager.retrieveBoundedBluetoothDevicesSerialized()
                if devices.isEmpty {
                    logger.log("No bounded devices was found.")
                } else {
                    logger.log("Retrieved \(devices.count) bluetooth device.")
                }
                callback(.success(devices))
            } catch {
                callback(.failure(error))
            }
        }
    }
    
    private func connect(_ address: String, callback: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                let connected = try await self.obd2.connect(target: address)
                callback(.success(connected))
            } catch {
                callback(.failure(ConnectionErrors.cantConnectError))
            }
        }
    }
    
    private func initializeOBD(callback: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                if try await self.obd2.initializeOBD() {
                    callback(.success(true))
                } else {
                    callback(.failure(CommandErrors.commandExecutionError("Error initializing OBD adapter.")))
                }
            } catch {
                callback(.failure(error))
            }
        }
    }
    
    private func getFuelLevel(callback: @escaping (Result<String, ResponseError>) -> Void) {
        Task {
            do {
                let fuelLevel = try await self.obd2.getFuelLevel()
                callback(.success(fuelLevel))
            } catch {
                callback(.failure(ResponseError(message: "Can't get fuel level because of \(error)", matchRegex: false)))
            }
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        //        logger.log("[PLUGIN]: Got call=\(call.method) | args=\(String(describing: call.arguments))")
        switch call.method {
            case MethodsNames.SCAN_BLUETOOTH_DEVICES:
                if self.obd2.bluetoothManager.isPowredOn {
                    self.performBluetoothScan() { res in
                        switch res {
                            case .success(let devices):
                                result(devices)
                            case .failure(let error):
                                result(error.localizedDescription)
                        }
                    }
                } else {
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
                                self.logger.log("Connection to adapter result is \(connected)")
                                result(connected)
                            case .failure(let error):
                                self.logger.log(String(describing: error))
                                result(FlutterError(
                                    code: "400",
                                    message: "Can't connect to device. Please try again",
                                    details: nil
                                ))
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
                self.initializeOBD() { [self] res in
                    switch res {
                        case .success(let initialized):
                            logger.log("Initialized")
                            result(initialized)
                        case .failure(let error):
                            logger.log(String(describing: error))
                            result(FlutterError(
                                code: "400",
                                message: "Can't initialize the OBD adapter. Check if it's connected or it may be out-of-range",
                                details: nil))
                    }
                }
            case MethodsNames.GET_FUEL_LEVEL:
                self.getFuelLevel() { res in
                    switch res {
                        case .success(let fuelLevel):
                            self.logger.log("Got fuel level: \(fuelLevel)")
                            result(fuelLevel)
                        case .failure(let error):
                            result(FlutterError(code: "204", message: error.message, details: nil))
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
        }
    }
    
}
