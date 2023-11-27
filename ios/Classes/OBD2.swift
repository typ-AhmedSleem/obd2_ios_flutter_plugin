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
    private var delegate: OBD2Delegate?
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
        self.initBluetoothManager()
        logger.log("Created OBD2 instance.")
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
        //self.executionQueue.sync  {
            let initialCommands = [
                EchoOffCommand(),
                LineFeedOffCommand(),
                TimeoutCommand(timeout: 100),
                SelectProtocolCommand(obdProtocol: ObdProtocols.AUTO)
            ]
            for command in initialCommands {
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
                    return nil
                }
                self.delegate?.onCommandExecuted(command, hasResponse: expectResponse)
                return await command.execute(bleManager: bm, expectResponse: expectResponse)
            } else {
                return nil
            }
            //}
        } else {
            return nil
        }
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
        logger.log("Adapter received response: \(response)")
    }

}
