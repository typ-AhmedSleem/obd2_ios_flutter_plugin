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
    private let buffer : NSMutableArray
    private let cmd : String
    public var useImperialUnits : Bool
    private var rawData : String?
    public var responseDelayInMs : Int
    private var timeStart : Int
    private var timeEnd : Int
    
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
        // todo: Call all code below in a sync block
        // todo: Set the timeStart to current time
        timeStart = 0
        // todo: Send the command to peripheral bu calling sendCommand
        self.sendCommand(obd)
        // todo: Read the result by calling readResult
        self.readResult(obd)
        // todo: Set the timeEnd to current time
        timeEnd = 0
    }
    
    private func sendCommand(obd: OBD2) {
        fatalError("Not yet implemented")
    }
    
    private func readResult(obd: OBD2)  {
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
