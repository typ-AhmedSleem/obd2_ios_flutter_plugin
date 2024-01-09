//
//  BluetoothViewModel.swift
//  obd2
//
//  Created by AhmedSleem on 04/11/2023.
//

import Foundation

class OBD2 {
    
    //* Global runtime
    private let logger = Logger("OBD2")
    private var delegate: OBD2Delegate?
    private var lastFuelLevel: String = "--%"
    private let executionQueue = DispatchQueue(label: "com.typ.obd.OBD2Queue")
    
    //* BluetoothManager runtime
    public let bluetoothManager: BluetoothManager = BluetoothManager(delegate: nil)
    
    init() {
        self.delegate = self
        self.bluetoothManager.delegate = self
        logger.log("Created a new OBD2 instance.")
    }
    
    public func connect(target address: String) async throws -> Bool {
        guard self.bluetoothManager.isPowredOn else {
            logger.log("connect", "BluetoothManager hasn't yet poweredOn")
            return false
        }
        return try await bluetoothManager.connect(target: address)
    }
    
    /**
     * Executes sequence of commands to initialize the OBD adapter after successfully connecting to it
     */
    public func initializeOBD() async throws -> Bool {
        guard self.bluetoothManager.hasOpenWritingChannel else {
            throw CommandErrors.commandExecutionError("No channels are open for writing. Aboring...")
        }
        logger.log("initializeOBD", "Initializing adapter...")
        let initializeCommands = [
            EchoOffCommand(),
            LineFeedOffCommand(),
            TimeoutCommand(timeout: 100),
            SelectProtocolCommand(obdProtocol: ObdProtocols.AUTO)
        ]
        for command in initializeCommands {
            logger.log("initializeOBD", "Executing '\(command.cmd)' ...")
            _ = try await self.executeCommand(command, expectResponse: false)
        }
        self.logger.log("initializeOBD", "OBD2 adapter is now initialized.")
        return true
    }
    
    /** Call the command execution call in a async block and await for result if expectResponse is true */
    public func executeCommand(_ command: ObdCommand, expectResponse: Bool) async throws -> String? {
        return try await command.execute(bleManager: self.bluetoothManager, expectResponse: expectResponse)
    }
    
    public func getFuelLevel() async throws -> String {
        let fuelLevel = try await self.executeCommand(FuelLevelCommand(delay: 100), expectResponse: true)
        if let newFuelLevel = fuelLevel {
            self.lastFuelLevel = newFuelLevel
            return newFuelLevel
        } else {
            return self.lastFuelLevel
        }
    }
    
}

protocol OBD2Delegate {
    func onCommandExecuted(_ command: ObdCommand, hasResponse: Bool)
    func onResponseReceived(_ command: ObdCommand, response: String?)
}


extension OBD2: BluetoothManagerDelegate {
    
    func onAdapterConnected() {
        logger.log("onAdapterConnected", "OBD2 Adapter is now connected.")
        Task {
            // Initialize adapter
            let initialized = try await self.initializeOBD()
            if initialized {
                self.onAdapterInitialized()
            }
        }
    }
    
    func onAdapterInitialized() {
        logger.log("OBD2 adapter is now initialized and ready to interact.")
    }
    
    func onAdapterStateChanged(state: Int) {
        
    }
    
    func onAdapterDisconnected() {
        logger.log("OBD2 adapter has been disconnected.")
    }
    
    func onAdapterReceiveResponse(response: String?) {
    }
    
}


extension OBD2: OBD2Delegate {
    
    func onCommandExecuted(_ command: ObdCommand, hasResponse: Bool) {
    }
    
    func onResponseReceived(_ command: ObdCommand, response: String?) {
    }
    
}
