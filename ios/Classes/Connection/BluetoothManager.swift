import Foundation
import CoreBluetooth

class BluetoothManager : NSObject {
    
    //* Global runtime
    private let logger = Logger("BM")
    private let responseStation =  ResponseStation(queueSize: 50)
    public var delegate: BluetoothManagerDelegate?
    private var boundedDevices: [String: CBPeripheral] = [:]
    public var scannedDevicesUUIDs: [UUID] = []
    private var scanTimer: Timer? = nil
    
    public static let DELAY_SECONDS = 3
    
    //* Bluetooth runtime
    private var centralManager: CBCentralManager?
    private var obdAdapter: CBPeripheral?
    private var obdChannel: CBCharacteristic?
    private var channels: [String: CBCharacteristic] = [:]
    public var connected: Bool {
        get {
            // Check if the adapter is connected to central manager.
            return (self.obdAdapter?.state ?? .disconnected) == .connected
        }
    }
    public var state: CBManagerState {
        get {
            return self.centralManager?.state ?? .unknown
        }
    }
    public var isPowredOn: Bool {
        get {
            return self.centralManager != nil && self.state == .poweredOn
        }
    }
    public var hasOpenWritingChannel: Bool {
        get {
            // Check if adapter isn't connected
            if !self.connected {
                return false
            }
            // Check if channels are empty
            if self.channels.isEmpty {
                return false
            }
            // Check if channels has at least one channel with writting permissions
            var hasWritingChannel = false
            for (_, channel) in self.channels {
                if channel.properties.contains(.write) || channel.properties.contains(.writeWithoutResponse) {
                    hasWritingChannel = true
                    break
                }
            }
            return hasWritingChannel
        }
    }
    public var isScanning: Bool {
        get {
            return self.isPowredOn && self.centralManager?.isScanning ?? false
        }
    }
    
    public init(delegate: BluetoothManagerDelegate?) {
        super.init()
        self.delegate = delegate
        self.centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
        self.logger.log("init", "Bluetooth manager has been initialized.")
    }
    
    public func scanForDevices() async throws {
        if !self.isScanning {
            logger.log("stopScan", "Bluetooth scan started.")
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
            try await Task.sleep(nanoseconds: UInt64(BluetoothManager.DELAY_SECONDS * 1000 * 1_000_000))
            self.centralManager?.stopScan()
            logger.log("stopScan", "Bluetooth scan stopped.")
        }
    }
    
//    @objc
//    public func stopScan() {
//        if self.isScanning && self.scanTimer != nil {
//            logger.log("stopScan", "Stopping bluetooth scan...")
//            // Stop scan
//            self.centralManager?.stopScan()
//            // Invalidate timer
//            self.scanTimer?.invalidate()
//            self.scanTimer = nil
//            logger.log("stopScan", "Scan stopped.")
//        }
//    }
    
    /**
     * Retrieves list of connected-to-system BLE devices and also serializes each device
     * into a JSON string to be sent back to FlutterApp through MethodChannel
     */
    public func retrieveBoundedBluetoothDevicesSerialized() -> [String] {
        var devices: [String] = []
        self.logger.log("retrieveBoundedBluetoothDevicesSerialized", "Last scan result has \(self.scannedDevicesUUIDs.count) devices.")
        let devicesList: [CBPeripheral] = self.centralManager?.retrievePeripherals(withIdentifiers: self.scannedDevicesUUIDs) ?? []
        self.logger.log("Retrieved \(devicesList.count) devices.")
        for bleDevice in devicesList {
            //* Add the device to bounded devices
            self.boundedDevices[bleDevice.identifier.uuidString] = bleDevice
            let deviceName = bleDevice.name ?? bleDevice.identifier.uuidString
            let deviceMapped = ["name": deviceName, "address": bleDevice.identifier.uuidString]
            if let jsonDevice = deviceMapped.serializeToJSON() {
                devices.append(jsonDevice)
            }
        }
        return devices
    }
    
    public func connect(target address: String?) async throws -> Bool {
        if !self.isPowredOn {
            //* Not yet poweredOn. Report Bluetooth either poweredOff, unsupported or has error
            self.logger.log("connect", "BluetoothManager isn't initialized. CurrentState: \(BluetoothStates.of(self.state))")
            return false
        }
        if self.connected {
            //* Already connected. No need to connect again
            self.logger.log("connect", "Adapter is already connected.. Aborted 'connect' operation.")
            return true
        }
        if self.obdAdapter == nil {
            if let address = address {
                //* Retrieve device from bounded devices first
                self.obdAdapter = self.boundedDevices[address]
                //* Check again
                if self.obdAdapter == nil {
                    self.logger.log("connect", "Can't find the device at all. It may be out of range.")
                    // OBD adapter is either out of range or hasn't connected to system at first
                    return false
                }
            } else {
                return false
            }
        }
        // Connect to adapter
        self.logger.log("connect", "Connecting to adapter...")
        self.centralManager?.connect(obdAdapter!, options: [CBConnectPeripheralOptionNotifyOnConnectionKey: true])
        // Suspend for a 250ms waiting for runtime update
        try await Task.sleep(nanoseconds: 1000 * 1_000_000)
        guard self.connected else {
            throw ConnectionErrors.cantConnectError
        }
        return true // Connected
    }
    
    /**
     * Performs a characteristics discovery for each service
     * discovered on connected device
     *
     * NOTE: Results are delegated to CBPeripheralDelegate
     */
    private func discoverCharacteristics(device: CBPeripheral) {
        if let services = device.services {
            self.logger.log("discoverCharacteristics", "===== START SERVICE DISCOVERY =====")
            for service in services {
                logger.log("discoverCharacteristics", "Discovering characteristics of service: \(service.uuid)")
                //* Discover our chars with our specific UUIDs
                device.discoverCharacteristics(nil, for: service)
            }
            self.logger.log("discoverCharacteristics", "===== END SERVICE DISCOVERY =====")
        }
    }
    
    public func send(dataToSend: String) async throws {
        //* Check if device is connected and at least only one characteristics has been discovered
        guard self.hasOpenWritingChannel else {
            logger.log("send", "No channels are open for writing.")
            throw CommandErrors.commandExecutionError("No channels are open for writing.")
        }
        //* Get the bytes of the data to be sent encoded in utf8 format
        guard let data = dataToSend.data(using: .utf8) else {
            self.logger.log("send", "Can't send empty data.")
            throw CommandErrors.commandExecutionError("Can't send empty data.")
        }
        //* Send data adapter
        if let adapter = obdAdapter {
            for (uuid, channel) in self.channels {
                self.logger.log("send", "Writing '\(dataToSend.removeWhitespaces())' to channel: '\(uuid)'")
                if channel.properties.contains(.write) {
                    adapter.writeValue(data, for: channel, type: .withResponse)
                    continue
                }
                if channel.properties.contains(.writeWithoutResponse) {
                    adapter.writeValue(data, for: channel, type: .withoutResponse)
                    continue
                }
            }
        }
    }
    
    public func consumeNextResponse() -> ResponsePacket {
        let response = self.responseStation.consume()
        self.logger.log("Consumed a response packet. Payload: '\(response.decodePayload().removeWhitespaces())'")
        return response
    }
    
}

extension BluetoothManager: CBCentralManagerDelegate {
    
    /** [DELEGATED] Called when central manager has discovered a new peripheral while performing a scan */
    func centralManager( _ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let address = peripheral.identifier
        // Check whether the device is already in the list
        if self.scannedDevicesUUIDs.contains(address) {
            return
        }
        // Append the peripheral object to the list
        let name = peripheral.name ?? address.uuidString
        self.scannedDevicesUUIDs.append(address)
        self.logger.log("centralManager::didDiscover", "Discovered device: \(name) | \(address.uuidString)")
        if name == OBDConstants.OBD_ADAPTER_NAME {
            self.logger.log("centralManager::didDiscover", "Found adapter at address: \(address.uuidString)")
            // Stop scanning for devices
            self.centralManager?.stopScan()
            // Save a copy of adapter peripheral at runtime
            self.obdAdapter = peripheral
            self.boundedDevices[address.uuidString] = peripheral
            //* Connect to adapter
            Task {
                _ = try await self.connect(target: address.uuidString)
            }
        }
    }
    
    /** [DELEGATED] Called when a central manager did updated its state */
    func centralManagerDidUpdateState( _ central: CBCentralManager) {
        self.logger.log("centralManager::centralManagerDidUpdateState", "Bluetooth state has changed: \(BluetoothStates.of(central.state))")
        // Initialize the bluetooth manager if not yet initialized
        if central.state == .poweredOn {
            
        }
    }
    
    /** [DELEGATED] Called when a successful connection with the OBD adapter was established */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //* Discover services
        self.obdAdapter = peripheral
        self.obdAdapter?.delegate = self
        self.obdAdapter?.discoverServices(nil)
        self.delegate?.onAdapterConnected()
    }
    
    /** [DELEGATED] Called when the OBD adapter has disconnected or its connection was lost */
    func centralManager(central: CBCentralManager, didDisconnect peripheral: CBPeripheral, error: Error?) {
        self.obdAdapter?.delegate = nil
        self.logger.log("centralManager::didDisconnect", "Disconnected from \(peripheral.identifier.uuidString) | Reason: \(String(describing: error))")
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            self.logger.log("centralManager::didFailToConnect", "Failed to connect to adapter. Reason: \(error)")
        }
    }
    
}

extension BluetoothManager : CBPeripheralDelegate {
    
    /* [DELEGATED] Invoked when service discovery has completed */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            self.logger.log("centralManager::didDiscoverServices", "Error occurred while discovering services: \(error)")
            return
        }
        //* Discover Characteristics
        self.discoverCharacteristics(device: peripheral)
    }
    
    /* [DELEGATED] Invoked when characteristics discovery has completed */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            self.logger.log("centralManager::didDiscoverCharacteristicsFor", "Error occurred while discovering characteristics: \(error)")
            return
        }
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            peripheral.setNotifyValue(true, for: characteristic)
            let uuid = characteristic.uuid.uuidString
            self.channels[uuid] = characteristic
            self.logger.log("centralManager::didDiscoverCharacteristicsFor(\(service.uuid.uuidString))", "Subscribed to channel: \(uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            self.logger.log("centralManager::didUpdateValueFor", "Error reading response: \(error)")
            return
        }
        //* Build a new packet for received data and push it to station
        if let response = characteristic.value {
            let responsePacket = ResponsePacket(payload: response)
            // Check if response starts with standard fuel level response: 41 2F
            let payload = responsePacket.decodePayload()
            if payload.hasPrefix("41 2F") {
                self.responseStation.push(packet: responsePacket)
                self.logger.log("centralManager::didUpdateValueFor", "Pushed a new response to response station with new fuel level value.")
            } else {
                logger.log("centralManager::didUpdateValueFor", "Received response but non-numeric: \(responsePacket.decodePayload().removeWhitespaces())")
            }
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let channelId = characteristic.uuid.uuidString
        if let error = error {
            self.logger.log("centralManager::didWriteValueFor", "Error writing to channel: \(channelId) | Reason: \(error)")
            return
        }
        self.logger.log("centralManager::didWriteValueFor", "Wrote something to channel: \(channelId)")
    }
    
}

