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
    
    private func executeWithTimeout(bleManager: BluetoothManager, expectResponse: Bool) async -> String? {
        do {
            let timeout: TimeInterval = self.responseDelayInMs / 1000
            let response = try await withTaskCancellationHandler(timeoutDuration: timeout) { ck in
                return try await self.execute(bleManager, expectResponse)
            }
            return response
        } catch {
            logger.log("Error while executing command: \(error)")
            return nil
        }
    }

    public func execute(bleManager: BluetoothManager, expectResponse: Bool) async -> String? {
        do {    
            // Time the start of execution
            self.timeStart = TimeHelper.currentTimeInMillis()
            // Send the command to peripheral by calling sendCommand
            try await self.sendCommand(bm: bleManager)
            // Hold thread for a delay if presented
            if self.responseDelayInMs > 0 {
                try await Task.sleep(nanoseconds: self.responseDelayInMs * 1_000_000)
            }
            var response: String? = nil
            if expectResponse {
                // Read the result by calling readResult
                response = try await self.readResult(bm: bleManager)
            }
            // Time the end of execution
            self.timeEnd = TimeHelper.currentTimeInMillis()
            // log
            logger.log("Executed: cmd='\(self.cmd)', res='\(self.response)' took= \(self.timeEnd - self.timeStart) ms")
            return response
        } catch {
            logger.log("Error while executing command: \(error)")
            return nil
        }
    }

    /**
     * Sends the OBD-II request.
     */
    private func sendCommand(bm: BluetoothManager) async throws {
        try await bm.send(cmd: self.cmd)
    }
    
    /**
     * Reads the OBD-II response.
     */
    private func readResult(bluetoothManager: bluetoothManager) async throws {
        await self.readRawBytes(bm: bluetoothManager)
        try await self.checkForErrors()
        await self.fillBuffer()
        await performCalculations()
    }
    
    private func readRawBytes(bm bleManager: BluetoothManager) async {
        // todo: Check latest ResponseHolder instance in BLEManager
        // todo: Consume that response if not yet consumed
    }
    
    private func checkForErrors() async throws {
        if self.rawData == nil {
            return
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
            error.setCommand(self)
            if error.check(self.rawData) {
                throw error
            }
        }
    }
    
    /**
     * Resolves the rawData of response and fill buffer with valid response bytes
     */
    private func fillBuffer() async {
        fatalError("Not yet implemented")
    }
    
    /**
     * This method exists so that for each command, there must be a method that is
     * called only once to perform calculations.
     */
    func performCalculations() async {
        fatalError("This method should be overridden.")
    }
    
    public func getFormattedResult() -> String {
        fatalError("This method should be overridden.")
    }

    public func getResult() -> String {
        return self.rawData
    }

    public func getResultUnit() -> String {
        fatalError("This method should be overridden.")
    }

}
