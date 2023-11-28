//
//  ObdCommand.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//
import Foundation
import CoreBluetooth

open class ObdCommand {
    
    private let logger: Logger
    //* Obd command variables
    internal let buffer : NSMutableArray
    public let cmd : String
    public var useImperialUnits : Bool
    internal var rawData : String?
    public var responseDelayInMs : Int
    internal var timeStart : Int64
    internal var timeEnd : Int64
    
    private let MAX_RESPONSE_DELAY = 250

    public init(_ command: String) {
        self.buffer = NSMutableArray()
        self.cmd = command
        self.useImperialUnits = true
        self.rawData = nil
        self.responseDelayInMs = 0
        self.timeStart = -1
        self.timeEnd = -1
        self.logger = Logger("ObdCommand::\(command)")
        logger.log("Created command: \(self.cmd)")
    }

    /** Executes the holding command and return its response if expecting.
    *!  CAUTION: This method doesn't check for channels or adapter connection
    *!  so, when calling it, you must ensure that adapter is connected and channel was discovered and open
    */
    func execute(bleManager: BluetoothManager, expectResponse: Bool) async -> String? {
        do {    
            // Time the start of execution
            self.timeStart = TimeHelper.currentTimeInMillis()
            // Send the command to peripheral by calling sendCommand
            try await self.sendCommand(bm: bleManager)
            // Hold thread for a delay if presented
            if self.responseDelayInMs > 0 {
                try await Task.sleep(nanoseconds: UInt64(self.responseDelayInMs * 1_000_000))
            }
            var response: String? = nil
            if expectResponse {
                // Read the result by calling readResult
                response = try await self.readResult(bluetoothManager: bleManager)
            }
            // Time the end of execution
            self.timeEnd = TimeHelper.currentTimeInMillis()
            // log
            logger.log("Executed: cmd='\(self.cmd)', res='\(self.getFormattedResult())' took= \(self.timeEnd - self.timeStart) ms")
            return response
        } catch {
            logger.log("Error while executing command. Reason: \(error)")
            return nil
        }
    }

    /**
     * Sends the OBD-II request.
     */
    private func sendCommand(bm: BluetoothManager) async throws {
        logger.log("Sending command: \(self.cmd)")
        try await bm.send(dataToSend: self.cmd)
    }
    
    /**
     * Reads the OBD-II response.
     */
    private func readResult(bluetoothManager: BluetoothManager) async throws -> String? {
        await self.readRawBytes(bm: bluetoothManager)
        try await self.checkForErrors()
        await self.fillBuffer()
        await performCalculations()
        return self.getFormattedResult()
    }
    
    private func readRawBytes(bm bleManager: BluetoothManager) async {
        //* Consume the very first packet on ResponseStation instance
        let packet = bleManager.consumeNextResponse()
        self.rawData = packet.decodePayload()
    }
    
    public func checkForErrors() async throws {
        if self.rawData == nil {
            throw NoDataError()
        }
        let errors = [
            NoDataError(),
            BusInitError(),
            MisunderstoodCommandError(),
            InvalidResponseError(),
            StoppedError(),
            UnableToConnectError(),
            UnknownError(),
            UnSupportedCommandError()
        ]
        //* Iterate over errors and check response against every single possible error
        for error in errors {
            error.setCommand(command: self.cmd)
            if error.check(response: self.rawData ?? "") {
                throw error
            }
        }
    }
    
    /**
     * Resolves the rawData of response and fill buffer with valid response bytes
     */
    private func fillBuffer() async {
        logger.log("fillBuffer: NOT YET IMPLEMENTED")
    }
    
    /**
     * This method exists so that for each command, there must be a method that is
     * called only once to perform calculations.
     */
    func performCalculations() async {
        
    }
    
    public func getFormattedResult() -> String {
        //fatalError("This method should be overridden.")
        return "NO RESULT"
    }

    public func getResult() -> String? {
        return self.rawData
    }

    public func getResultUnit() -> String {
       return "?"
    }

}
