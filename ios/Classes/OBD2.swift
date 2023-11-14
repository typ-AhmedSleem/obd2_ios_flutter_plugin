//
//  BluetoothViewModel.swift
//  obd2
//
//  Created by AhmedSleem on 04/11/2023.
//

import Foundation

class OBD2 : NSObject, BluetoothManagerDelegate {

    //* Global runtime
    private let logger = Logger("OBD2")
    private var delegate: OBD2Delegate?
    private let executionQueue = DispatchQueue(label: "com.typ.obd.OBD2Queue")

    //* BluetoothManager runtime
    public var bluetoothManager: BluetoothManager?
    public var isBLEManagerInitialized: Bool {
        get {
            return self.bluetoothManager != null && self.bluetoothManager.isInitialized
        }
    }

    //* OBD2 related
    private let INITIAL_COMMANDS: [ObdProtocolCommand]

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

    public func initBluetoothManager() {
        if self.bluetoothManager == nil {
            self.bluetoothManager = BluetoothManager(delegate: self)
        }
    }

    public func connect(target address: String) async -> Bool {
        return await self.bluetoothManager.connect(target: address)
    }

    /**
    * Executes sequence of commands to initialize the OBD adapter after successfully connecting to it
    */
    public func initializeOBD() async {
        self.executionQueue.sync {
            for command in self.INITIAL_COMMANDS {
                await self.executeCommand(command, expectResponse: false)
            }
        }
    }
    
    /** Call the command execution call in a async block and await for result if expectResponse is true */
    public func executeCommand(_ command: ObdCommand?, expectResponse: Bool) async -> String? {
        if command == nil {
            return nil
        }
        self.executionQueue.sync {
            if !self.bluetoothManager.isChannelOpened {
                return nil
            }
            self.onCommandExecuted(command: command, hasResponse: expectResponse)
            return await command?.execute(bleManager: self.bluetoothManager, expectResponse: expectResponse)
        }
    }

}

protocol OBD2Delegate {
    func onCommandExecuted(_ command: ObdCommand, hasResponse: Bool)
    func onResponseReceived(_ command: ObdCommand, response: String?)
}


extension OBD2: BluetoothManagerDelegate {

    // todo: implement the delegate functions BluetoothManagerDelegate 

}