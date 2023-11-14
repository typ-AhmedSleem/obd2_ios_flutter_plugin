import Foundation
import CoreBluetooth

class BluetoothManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    //* Global runtime
    private let logger = Logger("BLEManager")
    private var delegate: BluetoothManagerDelegate?
    private var boundedDevices: [String: CBPeripheral] = []

    //* Bluetooth runtime
    private var centralManager: CBCentralManager?
    private var obdAdapter: CBPeripheral?
    private var obdChannel: CBCharacteristics?
    private var channels: [String, CBCharacteristics] = []
    public var connected: Bool = false
    public var state: CBManagerState {
        get {
            return self.centralManager?.state ?? .unknown
        }
    }
    public var isInitialized: Bool {
        get {
            return self.centralManager != nil && self.state == .poweredOn
        }
    }
    public var isChannelOpened: Bool {
        get {
            return self.connected && self.obdChannel != nil
        }
    }

    //* Flags for commands with expected responses
    private var flagWaitingForResponse: Bool = false
    private var flagReceivedResponse: Bool = false
    

    init(delegate: BluetoothManagerDelegate?, queue: dispatch_queue_t?, options: [String : Any]? = nil) {
        super.init()
        self.centralManager = CBCentralManager(delegate: delegate, queue: queue, options: options)
        logger.log("BLEManager has been initialized. State is: \(self.state)")
    }

    convenience init() {
        self.init(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
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
                client?.discoverCharacteristics(nil, for: service)
                if service.uuid == UUIDs.serviceUUID || service.uuid == UUIDs.charUUID {
                }
            }
            logger.log("Discovered chars count: \(discoveredCharsCount)")
            logger.log("===== END CHARACTERISTICS DISCOVERY =====")
        }
    }

    /**
    * Retrieves list of connected-to-system BLE devices and also serializes each device 
    * into a JSON string to be sent back to FlutterApp through MethodChannel
    */
    public func retrieveBoundedBluetoothDevicesSerialized() async -> [String] {
        var devices: [String] = []
        let boundedDevices: [CBPeripheral]  = self.centralManager?.retrieveConnectedPeripherals(withServices: nil)
        for bleDevice: CBPeripheral in boundedDevices {
            if bleDevice == nil {
                continue
            }
            if bleDevice.name != nil {
                //* Add the device to bounded devices
                self.boundedDevices[bleDevice.identifier.uuidString] = bleDevice
            }
            let deviceMapped = ["name": bleDevice.name ?? "unnamed device", "address": bleDevice.identifier.uuidString]
            if let jsonDevice = deviceMapped.serializeToJSON() {
                devices.append(jsonDevice)
            }
        }
        logger.log("retrieveBoundedBluetoothDevicesSerialized: \(devices)")
        return devices
    }

    public func connect(target address: String) async -> Bool {
        if !self.isInitialized {
            //* Not initialized. Report Bluetooth either poweredOff, unsupported or has error
            return false
        }
        if self.connected {
            //* Already connected. No need to connect again
            return true
        }
        if self.obdAdapter == nil {
            guard address != nil else { return false }
            //* Retrieve device in bounded devices first
            self.obdAdapter = self.boundedDevices[address]
            //* Check again
            if self.obdAdapter == nil {
                //* OBD adapter is either out of range or hasn't connected to system at first
                return false
            }
        }
        //* Connect to adapter
        self.centralManager?.connect(obdAdapter, options: [
            CBConnectPeripheralOptionEnableAutoReconnect: true,
            CBConnectPeripheralOptionNotifyOnDisconnectionKey: true,
            CBConnectPeripheralOptionNotifyOnConnectionKey: true
        ])
        //* Notify the delegate
        self.delegate?.onAdapterConnected()
        return self.connected
    }

    public func send(dataToSend: String) async throws {
        //* Check if device is connected and at least only one characteristics has been discovered
        guard self.obdChannel != nil else { throw CommandExecutionError() }
        //* Get the bytes of the data to be sent encoded in utf8 format
        guard let data = dataToSend.data(using: .utf8) else { throw CommandExecutionError() }
        //* Send data adapter
        self.obdChannel.writeValue(data!, for: characteristic, type: .withResponse)
        //* Raise/Lower proper flags
        self.flagWaitingForResponse = false
        self.flagReceivedResponse = false
    }

}

extension BluetoothManager: CBCentralManagerDelegate {

    /** [DELEGATED] Called when central manager has discovered a new peripheral while performing a scan */
    func centralManager( _ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Log
        let name = peripheral.name ?? "unnamed device"
        logger.log("Found device: \(name)")
        logger.log("\t\(advertisementData)")
        logger.log("=======================")
    }
    
    /** [DELEGATED] Called when a central manager did updated its state */
    func centralManagerDidUpdateState( _ central: CBCentralManager) {
        logger.log("BLE state has changed: \(self.state)")
    }

    /** [DELEGATED] Called when a successful connection with the OBD adapter was established */
    func centralManager( central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //* Discover services
        self.connected = true
        self.centralManager?.discoverServices(nil)
        logger.log("Connected to \(peripheral.name)")
    }

    /** [DELEGATED] Called when the OBD adapter has disconnected or its connection was lost */
    func centralManager(central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        logger.log("Disconnected from \(peripheral.name) | Reason: \(error)")
    }
        
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.log("Error occurred while connecting: \(error)")
    }
    
}

extension BluetoothManager : CBPeripheralDelegate {

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
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error != nil else {
            logger.log("Error occurred while discovering characteristics: \(error)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // todo: If we need to subscribe to this channel, uncomment next line
            // characteristic.setNotifyValue(true)
            guard let uuid = characteristic.uuid.uuidString else { continue }
            self.channels[uuid] = characteristic
            logger.log("Discovered a characteristic: \(uuid)")
        }
        // todo: Notify the delegate that BluetoothManager is ready to send/receive data to/from device
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.log("Error reading response: \(error)")
        }
        //* Update flags on response
        if self.flagWaitingForResponse {
            self.flagWaitingForResponse = false
            self.flagReceivedResponse = true
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            logger.error("Error sending data: \(error)")
        }
    }

}

