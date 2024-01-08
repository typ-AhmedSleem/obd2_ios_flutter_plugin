//
//  BluetoothViewModel.swift
//  obd2
//
//  Created by AhmedSleem on 04/11/2023.
//

import Foundation

class OBD2 : NSObject {
    
    // todo: Use executionQueue for async-wait public functions instead of using Tasks
    
    //* Global runtime
    private let logger = Logger("OBD2")
    private var delegate: OBD2Delegate?
    private var lastFuelLevel: String = "--%"
    private let executionQueue = DispatchQueue(label: "com.typ.obd.OBD2Queue")
    
    //* BluetoothManager runtime
    public var bluetoothManager: BluetoothManager?
    public var isBLEManagerInitialized: Bool {
        get {
            // Check if bluetooth manager is nil
            if self.bluetoothManager == nil {
                return false
            }
            // Check if bluetooth manager is not yet powered on
            if !self.bluetoothManager!.isPowredOn {
                return false
            }
            // Check if bluetooth manager has at least one open channel for writing
            return self.bluetoothManager?.hasOpenWritingChannel ?? false
        }
    }
    
    override init() {
        super.init()
        self.delegate = self
        self.initBluetoothManager()
        logger.log("Created a new OBD2 instance.")
    }
    
    public func initBluetoothManager() {
        if self.bluetoothManager == nil {
            self.bluetoothManager = BluetoothManager(delegate: self)
        }
    }
    
    public func connect(target address: String) async -> Bool {
        guard self.isBLEManagerInitialized else {
            logger.log("connect", "BluetoothManager hasn't yet initialized")
            return false
        }
        return await bluetoothManager?.connect(target: address) ?? false
    }
    
    /**
     * Executes sequence of commands to initialize the OBD adapter after successfully connecting to it
     */
    public func initializeOBD() async {
        logger.log("initializeOBD", "Initializing adapter...")
        let initializeCommands = [
            EchoOffCommand(),
            LineFeedOffCommand(),
            TimeoutCommand(timeout: 100),
            SelectProtocolCommand(obdProtocol: ObdProtocols.AUTO)
        ]
        for command in initializeCommands {
            logger.log("initializeOBD", "Executing '\(command.cmd)' ...")
            _ = await self.executeCommand(command, expectResponse: false)
        }
        self.logger.log("initializeOBD", "OBD2 adapter is now initialized.")
    }
    
    /** Call the command execution call in a async block and await for result if expectResponse is true */
    public func executeCommand(_ command: ObdCommand, expectResponse: Bool) async -> String? {
        if let bm = self.bluetoothManager {
            return await command.execute(bleManager: bm, expectResponse: expectResponse)
        } else {
            return nil
        }
    }
    
    public func getFuelLevel() async -> String? {
        let fuelLevel = await self.executeCommand(FuelLevelCommand(delay: 100), expectResponse: true)
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
        logger.log("onAdapterConnected", "Adapter connected.")
        Task {
            // Initialize adapter
            await self.initializeOBD()
            self.onAdapterInitialized()
        }
    }
    
    func onAdapterInitialized() {
        logger.log("Adapter has been initialized.")
    }
    
    func onAdapterStateChanged(state: Int) {
        logger.log("Adapter state has changed to: \(state)")
    }
    
    func onAdapterDisconnected() {
        logger.log("Adapter disconnected.")
    }
    
    func onAdapterReceiveResponse(response: String?) {
        logger.log("Adapter received response: \(String(describing: response))")
    }
    
}


extension OBD2: OBD2Delegate {
    
    func onCommandExecuted(_ command: ObdCommand, hasResponse: Bool) {
    }
    
    func onResponseReceived(_ command: ObdCommand, response: String?) {
    }
    
}
