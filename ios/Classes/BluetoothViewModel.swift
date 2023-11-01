import CoreBluetooth

class BluetoothViewModel : NSObject, ObservableObject {
    private var centralManager : CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    @Published var peripheralNames: [String] = []

    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
}

extension BluetoothViewModel: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.centralManager?.scanForPeripherals(withService: nil)
        }
    }

    func centralManager( central: CBCentralManager, 
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // * Add peripheral to list if not already added
        if !peripherals.contains(peripheral) {
            self.peripherals.append(peripheral)
            self.peripheralNames.append(peripheral.name ?? "unnamed device")
        }
        }
}