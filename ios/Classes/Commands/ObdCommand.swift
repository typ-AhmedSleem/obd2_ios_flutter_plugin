//
//  ObdCommand.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//
import Foundation
import CoreBluetooth

open class ObdCommand {
    
    // Obd command variables
    internal let buffer : NSMutableArray
    public let cmd : String
    public var useImperialUnits : Bool
    internal var rawData : String?
    public var responseDelayInMs : Int
    internal var timeStart : Int
    internal var timeEnd : Int
    
    private let MAX_RESPONSE_DELAY = 250

    public init(command: String) {
        self.buffer = NSMutableArray()
        self.cmd = command
        self.useImperialUnits = true
        self.rawData = nil
        self.responseDelayInMs = 0
        self.timeStart = -1
        self.timeEnd = -1
    }
    
    public func execute(obd: OBD2) {
        // Time the start of execution
        self.timeStart = TimeHelper.currentTimeInMillis()
        // Send the command to peripheral bu calling sendCommand
        self.sendCommand(obd)
        // Time the end of execution
        self.timeEnd = TimeHelper.currentTimeInMillis()
    }

    public func executeAndWaitResponse() {
        // Time the start of execution
        self.timeStart = TimeHelper.currentTimeInMillis()
        // Send the command to peripheral bu calling sendCommand
        self.sendCommand(obd)
        // Read the result by calling readResult
        let response = self.readResult(obd)
        // Time the end of execution
        self.timeEnd = TimeHelper.currentTimeInMillis()
        return response
    }
    
    private func sendCommand(obd: OBD2) {
        fatalError("Not yet implemented")
    }
    
    private func readResult(obd: OBD2)  {
        // todo: Don't forget to hold thread here if responseDelayInMs is provided with value > 0
        self.readRawBytes(obd)
        self.checkForErrors()
        self.fillBuffer()
        performCalculations()
    }
    
    private func readRawBytes(obd: OBD2) {
        fatalError("Not yet implemented")
    }
    
    private func checkForErrors() {
        fatalError("Not yet implemented")
    }
    
    /**
     */
    private func resolveResult() {
        fatalError("Not yet implemented")
    }
    
    private func fillBuffer() {
        fatalError("Not yet implemented")
    }
    
    func performCalculations() {
        fatalError("This method should be overridden.")
    }
    
    public func getFormattedResult() -> String {
        fatalError("This method should be overridden.")
    }

    public func getResult() -> String {
        return rawData
    }

    public func getResultUnit() -> String {
        fatalError("This method should be overridden.")
    }

}
