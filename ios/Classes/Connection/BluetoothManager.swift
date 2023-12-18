import Foundation
import CoreBluetooth

class BluetoothManager : NSObject {

    //* Global runtime
    private let logger = Logger("BLEManager")
    private let responseStation =  ResponseStation(queueSize: 50)
    private var delegate: BluetoothManagerDelegate?
    private var boundedDevices: [String: CBPeripheral] = [:]
    private var scannedDevicesUUIDs: [UUID] = []

    //* Bluetooth runtime
    private var centralManager: CBCentralManager?
    private var obdAdapter: CBPeripheral?
    private var obdChannel: CBCharacteristic?
    private var channels: [String: CBCharacteristic] = [:]
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
            return self.connected && !self.channels.isEmpty
        }
    }
    public var isScanning: Bool {
        get {
            return self.isInitialized && self.centralManager?.isScanning ?? false
        }
    }
    
    public init(delegate: BluetoothManagerDelegate?) {
        super.init()
        self.delegate = delegate
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        self.logger.log("BLEManager has been initialized. State is: \(self.state)")
    }
    
    public func scanForDevices() {
        if !self.isScanning {
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        }
    }

    /**
    * Retrieves list of connected-to-system BLE devices and also serializes each device 
    * into a JSON string to be sent back to FlutterApp through MethodChannel
    */
    public func retrieveBoundedBluetoothDevicesSerialized() -> [String] {
        var devices: [String] = []
        let devicesList: [CBPeripheral]  = self.centralManager?.retrievePeripherals(withIdentifiers: self.scannedDevicesUUIDs) ?? []
        self.logger.log("Retrieved \(devicesList.count) devices.")
        for bleDevice: CBPeripheral in devicesList {
            if bleDevice.name != nil {
                //* Add the device to bounded devices
                self.boundedDevices[bleDevice.identifier.uuidString] = bleDevice
            }
            let deviceMapped = ["name": bleDevice.name ?? "unnamed device", "address": bleDevice.identifier.uuidString]
            if let jsonDevice = deviceMapped.serializeToJSON() {
                devices.append(jsonDevice)
                self.logger.log(jsonDevice)
            }
            
        }
        self.logger.log("retrieveBoundedBluetoothDevicesSerialized: \(devices)")
        return devices
    }

    public func connect(target address: String?) async -> Bool {
        if !self.isInitialized {
            //* Not initialized. Report Bluetooth either poweredOff, unsupported or has error
            self.logger.log("BluetoothManager isn't initialized. CurrentState: \(self.state)")
            return false
        }
        if self.connected {
            //* Already connected. No need to connect again
            self.logger.log("Adapter is already connected")
            return true
        }
        if self.obdAdapter == nil {
            if let address = address {
                //* Retrieve device in bounded devices first
                self.obdAdapter = self.boundedDevices[address]
                //* Check again
                if self.obdAdapter == nil {
                    self.logger.log("Can't find the device at all. It may be out of range.")
                    // OBD adapter is either out of range or hasn't connected to system at first
                    return false
                }
            } else {
                return false
            }
        }
        self.logger.log("Connecting to adapter...")
        //* Connect to adapter
        self.centralManager?.connect(obdAdapter!, options: nil)
        return self.connected
    }

    /**
    * Performs a characteristics discovery for each service
    * discovered on connected device
    *
    * NOTE: Results are delegated to CBPeripheralDelegate
    */
    private func discoverCharacteristics(client: CBPeripheral?) {
        if let services = client?.services {
            self.logger.log("===== START SERVICE DISCOVERY =====")
            for service in services {
                logger.log("\tDiscovering characteristics of service: \(service.uuid)")
                //* Discover our chars with our specific UUIDs
                client?.discoverCharacteristics(nil, for: service)
            }
            self.logger.log("===== END SERVICE DISCOVERY =====")
        }
    }

    public func send(dataToSend: String) async throws {
        //* Check if device is connected and at least only one characteristics has been discovered
        guard self.isChannelOpened else {
            self.logger.log("Neither adapter is connected nor at least one channel is opened.")
            throw CommandExecutionError()
        }
        //* Get the bytes of the data to be sent encoded in utf8 format
        guard let data = dataToSend.data(using: .utf8) else { 
            self.logger.log("Can't send empty data.")
            throw CommandExecutionError()
        }
        //* Send data adapter
        if let adapter = obdAdapter {
            for channel in self.channels.keys {
                if let chr = self.channels[channel] {
                    if chr.properties.contains(.write) {
                        self.logger.log("Writing with response: '\(String(data: data, encoding: .utf8) ?? "")' to channel: '\(channel)'")
                        adapter.writeValue(data, for: chr, type: .withResponse)
                        continue
                    }
                    if chr.properties.contains(.writeWithoutResponse) {
                        self.logger.log("Writing without response: '\(String(data: data, encoding: .utf8) ?? "")' to channel: '\(channel)'")
                        adapter.writeValue(data, for: chr, type: .withoutResponse)
                        continue
                    }
                    self.logger.log("Charac: \(chr.uuid.uuidString) has value: \(ResponsePacket(payload: chr.value ?? Data()).decodePayload())")
                }
            }
        }
    }

    public func consumeNextResponse() -> ResponsePacket {
        let response = self.responseStation.consume()
        self.logger.log("Consumed a response packet. Payload: '\(response.decodePayload())'")
        return response
    }

}

extension BluetoothManager: CBCentralManagerDelegate {

    /** [DELEGATED] Called when central manager has discovered a new peripheral while performing a scan */
    func centralManager( _ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? "unnamed device"
        let address = peripheral.identifier
        self.scannedDevicesUUIDs.append(address)
        self.logger.log("\nDiscovered BLE device: \(name) | \(address.uuidString)")
        if name == OBDConstants.OBD_ADAPTER_NAME && !self.isChannelOpened {
            self.logger.log("Found adapter at address: \(address.uuidString)")
            // Stop scanning for devices
            self.centralManager?.stopScan()
            // Save a copy of adapter peripheral at runtime
            self.obdAdapter = peripheral
            self.boundedDevices[address.uuidString] = peripheral
            // Connect to adapter
            self.logger.log("Connecting to adapter...")
            //* Connect to adapter
            Task {
                await self.connect(target: address.uuidString)
            }
        }
    }
    
    /** [DELEGATED] Called when a central manager did updated its state */
    func centralManagerDidUpdateState( _ central: CBCentralManager) {
        self.logger.log("BLE state has changed: \(self.state)")
    }

    /** [DELEGATED] Called when a successful connection with the OBD adapter was established */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //* Discover services
        self.connected = true
        self.obdAdapter?.delegate = self
        self.obdAdapter?.discoverServices(nil)
        self.delegate?.onAdapterConnected()
        self.logger.log("Connected to \(peripheral.identifier.uuidString)")
    }

    /** [DELEGATED] Called when the OBD adapter has disconnected or its connection was lost */
    func centralManager(central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
        self.connected = false
        self.obdAdapter?.delegate = nil
        self.logger.log("Disconnected from \(peripheral.identifier.uuidString) | Reason: \(String(describing: error))")
    }
        
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.connected = false
            self.logger.log("Error occurred while connecting: \(error)")
        }
    }
    
}

extension BluetoothManager : CBPeripheralDelegate {

    /* [DELEGATED] Invoked when service discovery has completed */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.logger.log("Error occurred while discovering services: \(error)")
            return
        }
        //* Discover Characteristics
        self.discoverCharacteristics(client: peripheral)
    }

    /* [DELEGATED] Invoked when characteristics discovery has completed */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.logger.log("Error occurred while discovering characteristics: \(error)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
            let uuid = characteristic.uuid.uuidString
            self.channels[uuid] = characteristic
            self.logger.log("Subscribed to characteristic: \(uuid)")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.logger.log("Error reading response: \(error)")
            return
        }
        //* Build a new packet for received data and push it to station
        if let response = characteristic.value {
            let responsePacket = ResponsePacket(payload: response)
            self.responseStation.push(packet: responsePacket)
            self.logger.log("Pushed a new packet to the station. Payload: (\(responsePacket.decodePayload())) | Station now has \(self.responseStation.queueSize) of \(self.responseStation.maxQueueSize) packets.")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let channelId = characteristic.uuid.uuidString
        if let error = error {
            self.logger.log("Error writing to channel: \(channelId) | Reason: \(error)")
        }
        self.logger.log("Wrote something to channel: \(channelId)")
    }

}

