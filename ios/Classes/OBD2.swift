//
//  BluetoothViewModel.swift
//  obd2
//
//  Created by AhmedSleem on 04/11/2023.
//

import Foundation

class OBD2 : NSObject {

    //* Global runtime
    private let logger = Logger("OBD2")
    var delegate: OBD2Delegate?
    private let executionQueue = DispatchQueue(label: "com.typ.obd.OBD2Queue")

    //* BluetoothManager runtime
    public var bluetoothManager: BluetoothManager?
    public var isBLEManagerInitialized: Bool {
        get {
            return self.bluetoothManager != nil && self.bluetoothManager!.isInitialized
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
        guard let bm = self.bluetoothManager else { return false }
        guard bm.isInitialized else { 
            logger.log("BluetoothManager hasn't yet initialized")
            return false
        }
        return await bm.connect(target: address)
    }

    /**
    * Executes sequence of commands to initialize the OBD adapter after successfully connecting to it
    */
    public func initializeOBD() async {
        logger.log("Initializing adapter...")
        //self.executionQueue.sync  {
            let initialCommands = [
                EchoOffCommand(),
                LineFeedOffCommand(),
                TimeoutCommand(timeout: 100),
                SelectProtocolCommand(obdProtocol: ObdProtocols.AUTO)
            ]
            for command in initialCommands {
                logger.log("(initializeOBD): Executing '\(command.cmd)' ...")
                await self.executeCommand(command, expectResponse: false)
            }
       // }
    }
    
    /** Call the command execution call in a async block and await for result if expectResponse is true */
    public func executeCommand(_ command: ObdCommand?, expectResponse: Bool) async -> String? {
        if let command = command {
            //self.executionQueue.sync {
            if let bm = self.bluetoothManager {
                if !bm.isChannelOpened {
                    logger.log("Channel is closed")
                    return nil
                }
                self.delegate?.onCommandExecuted(command, hasResponse: expectResponse)
                return await command.execute(bleManager: bm, expectResponse: expectResponse)
            } else {
                return nil
            }
            //}
        } else {
            logger.log("Command is nil")
            return nil
        }
    }
    
    public func getFuelLevel() async -> String? {
        let fuelLevel = await self.executeCommand(FuelLevelCommand(delay: 100), expectResponse: true)
        
        
        return fuelLevel
    }

}

protocol OBD2Delegate {
    func onCommandExecuted(_ command: ObdCommand, hasResponse: Bool)
    func onResponseReceived(_ command: ObdCommand, response: String?)
}


extension OBD2: BluetoothManagerDelegate {
    func onAdapterConnected() {
        logger.log("Adapter connected.")
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
        // logger.log("Command \(command.cmd) executed")
    }
    
    func onResponseReceived(_ command: ObdCommand, response: String?) {
        
    }
    
    
}
