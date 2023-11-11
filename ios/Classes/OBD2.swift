//
//  BluetoothViewModel.swift
//  obd2
//
//  Created by AhmedSleem on 04/11/2023.
//

import Foundation
import CoreBluetooth

class OBD2 : NSObject, ObservableObject {

    //* Global runtime
    private let logger = Logger("OBD2")
    private var delegate: OBD2Delegate
    private let executionQueue = DispatchQueue(label: "com.typ.obd.OBD2Queue")

    //* Bluetooth related runtime
    private var centralManager : CBCentralManager?
    private var scannedDevices: [String: CBPeripheral] = []
    @Published var peripheralNames: [String] = []

    //* OBD related runtime
    private let INITIAL_COMMANDS: [ObdProtocolCommand]
    public var bleOn = false
    public var bleScanning = false
    public var bleConnected = false
    private var obdState = OBDState.OBD_READY
    private var device: CBPeripheral?

    override init() {
        super.init()
        self.INITIAL_COMMANDS = [
            EchoOffCommand(),
            LineFeedOffCommand(),
            TimeoutCommand(timeout: 100),
            SelectProtocolCommand(obdProtocol: ObdProtocols.AUTO),
        ]
        logger.log("Creating OBD2 instance...")
    }

    func getState() -> CBManagerState {
        return self.centralManager?.state ?? .unknown
    }

    func isBluetoothOn() -> Bool {
        return self.getState() == .poweredOn
    }

    func initBluetooth() -> Int {
        if self.centralManager == nil {
            //* [CBCentralManagerOptionShowPowerAlertKey] options means that OS will prompt user to enable BLE if not enabled (USEFUL ^-^)
            self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        }
        if self.centralManager?.state == .unsupported {
            return OBDState.OBD_BLE_UNSUPPORTED
        }
        if self.centralManager?.state == .poweredOn {
            logger.log("BLE has been initialized.")
        }
        return OBDStates.OBD_BLE_INITIALIZED
    }

    private func scanForDevice() -> [String: CBPeripheral] {
        if !isBluetoothScanning {
            //* Perform scan
            self.isBluetoothScanning = true
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
            self.isBluetoothScanning = false
        }
    }

    /**
    * Retrieves list of connected-to-system BLE devices and also serializes each device 
    * into a JSON string to be sent back to FlutterApp through MethodChannel
    */
    public func retrieveBoundedBluetoothDevicesSerialized() -> [String] {
        // todo: Move BLE related stuff to be accessed by BluetoothManager instance instead of CBCentralManager
        var devices: [String] = []
        let boundedDevices: [CBPeripheral]  = self.centralManager?.retrieveConnectedPeripherals(withServices: nil)
        for bleDevice: CBPeripheral in boundedDevices {
            if bleDevice == nil {
                continue
            }
            let deviceMapped = ["name": bleDevice.name ?? "unnamed device", "address": bleDevice.identifier.uuidString]
            if let jsonDevice = deviceMapped.serializeToJSON() {
                devices.append(jsonDevice)
            }
        }
        logger.log("retrieveBoundedBluetoothDevicesSerialized: \(devices)")
        return devices
    }

    func connect() -> Int {
        if !self.bleConnected {
            if self.device == nil {
                //* Try to get obd-adapter peripheral from scanned devices
                let tempDevice = self.scannedDevices[OBDConstants.OBD_ADAPTER_NAME]
                if tempDevice == nil {
                    return OBDStates.OBD_ADAPTER_OUT_OF_RANGE
                }
                self.device = tempDevice
            }
            //* Perform device connect attempt
            self.centralManager?.connect(self.device!, options: nil)
            return OBDStates.OBD_CONNECTING
        }
    }

    /**
    * Performs a characteristics discovery for each service
    * discovered on connected device
    *
    * NOTE: Results are delegated to CBPeripheralDelegate
    */
    private func discoverCharacteristics(client: CBPeripheral?) {
        if let services = client?.services {
            discoveredCharsCount = 0
            logger.log("===== START CHARACTERISTICS DISCOVERY =====")
            for service in services {
                logger.log("\tTrying with service: \(service.uuid)")
                //* Discover our chars with our specific UUIDs
                if service.uuid == UUIDs.serviceUUID || 
                    service.uuid == UUIDs.charUUID {
                        client?.discoverCharacteristics(nil, for: service)
                }
            }
            logger.log("Discovered chars count: \(discoveredCharsCount)")
            logger.log("===== END CHARACTERISTICS DISCOVERY =====")
        }
    }

    /**
    * Executes sequence of commands to initialize the OBD adapter after successfully connecting to it
    */
    private func initializeOBD() {
        self.executionQueue.sync {
            for command in self.INITIAL_COMMANDS {
                await self.executeCommand(command, expectResponse: false)
            }
        }
    }

    private func sendToClient() {
        
        self.executionQueue.sync {
            fatalError("Not yet Implemented.")
        }
    }

    private func readFromClient() {
        self.executionQueue.sync {
            fatalError("Not yet Implemented.")
        }
    }


    public func executeCommand(_ command: ObdCommand?, expectResponse: Bool) async -> String? {
        // todo: Call the command execution call in a async block and await for result if expectResponse is true
        if command == nil {
            return nil
        }
        self.executionQueue.async {
            self.onCommandExecuted(command: command, hasResponse: false)
            command?.execute(obd: self)
        }

    }

}

protocol OBD2Delegate {

    optional func onAdapterConnected()
    optional func onAdapterInitialized()
    optional func onAdapterStateChanged(state: ObdState)
    optional func onAdapterDisconnected()
    func onCommandExecuted(_ command: ObdCommand, hasResponse: Bool)
    func onResponseReceived(_ command: ObdCommand, response: String?)
}

extension OBD2: CBCentralManagerDelegate {

    func centralManager( _ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // * Add peripheral to list if not already added
        if !scannedDevices.contains(peripheral) {
            self.scannedDevices.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "unnamed device")
            //* Log
            let name = peripheral.name ?? "unnamed device"
            logger.log("Found device: \(name)")
            logger.log("\t\(advertisementData)")
            logger.log("=======================")
        }
    }
    
    func centralManagerDidUpdateState( _ central: CBCentralManager) {
        let state = central.state
        logger.log("Bluetooth state has changed: \(BluetoothStates.BT_MAPPED_STATE[state] ?? "nil")")
    }

    func centralManager( central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        self.bleConnected = true
        self.bleScanning = false
        logger.log("Connected to \(peripheral.name!)")
        //* Discover services
        self.centralManager?.discoverServices(nil)
    }

    func centralManager(central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
        self.bleConnected = true
        logger.log("Disconnected from \(peripheral.name) | Reason: \(error)")
    }
        
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.log("Error occurred while connecting: \(error)")
    }
    
}

extension OBD2 : CBPeripheralDelegate {

    /* [DELEGATED] Invoked when service discovery has completed */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            logger.log("Error occurred while discovering services: \(error)")
            return
        }
        //* Discover Characteristics
        self.discoverCharacteristics(peripheral)
    }

    /* [DELEGATED] Invoked when characteristics discovery has completed */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor: CBService, error: Error?) {
    }

}
