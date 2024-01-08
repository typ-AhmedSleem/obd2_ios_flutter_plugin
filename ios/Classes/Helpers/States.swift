//
//  BluetoothState.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

import CoreBluetooth

final class BluetoothStates {
    public static let BT_MAPPED_STATE = [
        CBManagerState.unknown : "Unknown",
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
