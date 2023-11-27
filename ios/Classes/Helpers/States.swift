//
//  BluetoothState.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

import CoreBluetooth

final class BluetoothStates {
    public static let BT_MAPPED_STATE = [
        CBManagerState.unknown : "UnKnown",
        CBManagerState.poweredOff : "PoweredOff",
        CBManagerState.resetting : "Resetting",
        CBManagerState.unsupported : "UnSupported",
        CBManagerState.unauthorized : "UnAuthorized",
        CBManagerState.poweredOn : "PoweredOn",
    ]
}

final class PeripheralStates {
    public static let PL_MAPPED_STATE = [
        CBPeripheralState.disconnecting : "Disconnecting",
        CBPeripheralState.disconnected : "Disconnected",
        CBPeripheralState.connecting : "Connecting",
        CBPeripheralState.connected : "Connected",
    ]
}

class OBDStates {
    public static let OBD_OFF = 0
    public static let OBD_BLE_ERROR = 1
    public static let OBD_BLE_UNSUPPORTED = 2 
    public static let OBD_CANT_CONNECT = 3
    public static let OBD_CANT_SEND_DATA = 4 
    public static let OBD_CANT_READ_DATA = 5 
    public static let OBD_BLE_INITIALIZED = 6 
    public static let OBD_CONNECTING = 7 
    public static let OBD_ADAPTER_OUT_OF_RANGE = 8 
    public static let OBD_READY = 9 
    // public static let OBD_ = 1 
    // public static let OBD_ = 1 
    // public static let OBD_ = 1 
    // public static let OBD_ = 1 
    // public static let OBD_ = 1 
}

