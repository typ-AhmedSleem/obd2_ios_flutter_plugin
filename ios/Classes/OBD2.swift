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

    //* Bluetooth related runtime
    private var centralManager : CBCentralManager?
    private var scannedDevices: [String: CBPeripheral] = []
    @Published var peripheralNames: [String] = []

    //* OBD related runtime
    // public var bleOn = false
    public var bleScanning = false
    public var bleConnected = false
    private var obdState = OBDState.OBD_READY
    private var device: CBPeripheral?

    override init() {
        super.init()
        logger.log("Creating OBD2 instance...")
    }

    func getStateMapped() -> String{
        return self.mappedState[self.getRawState()] ?? "NO-STATE"
    }

    func getRawState() -> Int {
        return self.centralManager?.state.rawValue ?? -1
    }

    func getState() -> CBManagerState {
        return self.centralManager?.state ?? .unknown
    }

    func isBluetoothOn() -> Bool {
        return self.getState() == .poweredOn
    }

    func isBluetoothScanning() -> Bool {
        return self.getState() == .scanning
    }

    func initBluetooth() -> Int {
        if self.centralManager == nil {
            self.centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        if self.centralManager?.state == .unsupported {
            return OBDState.OBD_BLE_UNSUPPORTED
        }
        if self.centralManager?.state == .poweredOn {
            logger.log("BLE has been initialized.")
        }
        return OBDState.OBD_BLE_INITIALIZED
    }

    func scanForDevice() -> [String: CBPeripheral] {
        if !self.isBluetoothScanning() {
            //* Perform scan
            self.isBluetoothScanning = true
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
            self.isBluetoothScanning = false
        }
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

    private func initializeOBD() {
        // todo: Run the init sequence at first run
        fatalError("Not yet implemented.")
    }

    private func sendToClient() {
        fatalError("Not yet Implemented.")
    }

    private func readFromClient() {
        fatalError("Not yet Implemented.")
    }

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
