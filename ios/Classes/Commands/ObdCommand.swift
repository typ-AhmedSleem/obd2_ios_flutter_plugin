//
//  ObdCommand.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//
import Foundation
import CoreBluetooth

open class ObdCommand {
    
    internal let logger: Logger

    public let cmd : String
    internal var response : String?
    internal var buffer : [Int] = []
    public var useImperialUnits : Bool
    public var responseDelayInMs : Int
    
    internal var timeStart : Int64
    internal var timeEnd : Int64
    
    private let MAX_RESPONSE_DELAY = 250

    public init(_ command: String) {
        self.buffer = []
        self.cmd = command
        self.response = nil
        self.timeStart = -1
        self.timeEnd = -1
        self.responseDelayInMs = 0
        self.useImperialUnits = true
        self.logger = Logger("ObdCmd::\(command)")
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
                response = try await self.readResult(bm: bleManager)
                self.response = response
            }
            // Time the end of execution
            self.timeEnd = TimeHelper.currentTimeInMillis()
            // log
            logger.log("Executed: cmd='\(self.cmd)', res='\(self.getFormattedResult())' took= \(self.timeEnd - self.timeStart) ms")
            return response
        } catch {
            logger.log("Error while executing command or while resolving response. Reason: \(error)")
            return nil
        }
    }

    /**
     * Sends the OBD-II request.
     */
    private func sendCommand(bm bleManager: BluetoothManager) async throws {
        logger.log("Sending command: \(self.cmd)")
        let readyCmd = self.cmd + "\r"
        try await bleManager.send(dataToSend: readyCmd)
    }
    
    /**
     * Reads the OBD-II response and resolve it and return its formatted result
     */
    private func readResult(bm bleManager: BluetoothManager) async throws -> String? {
        try await self.readRawBytes(bm: bleManager)
        try await self.checkForErrors()
        try await self.fillBuffer()
        try await performCalculations()
        return self.getFormattedResult()
    }
    
    private func readRawBytes(bm bleManager: BluetoothManager) async throws {
        //* Consume the very first packet on ResponseStation instance
        let packet = bleManager.consumeNextResponse()
        var rawResponse = packet.decodePayload()
        guard !rawResponse.isEmpty else {
            throw ResolverErrors.emptyResponse
        }
        self.logger.log("readRawBytes", "Raw response: '\(rawResponse)'")
        // Remove Searching from response
        rawResponse = RegexMatcher.replaceInString(pattern: RegexPatterns.SEARCHING_PATTERN, original: rawResponse, replacement: "")
        // Remove whitespaces, invalid chars and escape letters from response
        rawResponse = RegexMatcher.replaceInString(pattern: RegexPatterns.WHITESPACE_PATTERN, original: rawResponse, replacement: "")
        
        self.response = rawResponse
        self.logger.log("readRawBytes", "Ready raw response: '\(self.response ?? "")'")
    }
    
    public func checkForErrors() async throws {
        if self.response == nil {
            self.logger.log("checkForErrors", "Response is empty. Aborting...")
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
            if error.check(response: self.response ?? "") {
                self.logger.log("checkForErrors", "Checker found \(type(of: error)) match in response")
                throw error
            }
            self.logger.log("checkForErrors", "Passed '\(type(of: error))'")
        }
    }
    
    /**
     * Resolves the rawData of response and fill buffer with valid response bytes
     */
    private func fillBuffer() async throws {
        //* Take a copy of response
        var response = self.response ?? ""
        //* Remove all whitespaces and line breaks from response
        response = RegexMatcher.replaceInString(pattern: RegexPatterns.WHITESPACE_PATTERN, original: response, replacement: "")
        //* Remove BUS INIT from response
        response = RegexMatcher.replaceInString(pattern: RegexPatterns.BUSINIT_PATTERN, original: response, replacement: "")
        //* Check one more time if the response is nil or empty
        guard response != nil && !response.isEmpty else { 
            throw ResolverErrors.emptyResponse
        }
        //* Check whether response has numeric output
        guard RegexMatcher.isMatchingRegex(inputString: response, regexPattern: RegexPatterns.DIGITS_LETTERS_PATTERN) else {
            self.logger.log("fillBuffer", "Response is either invalid or contains non numeric values.")
            throw ResolverErrors.invalidResponse
        }
        //* Resolve the response and fill buffer
        guard let rawBytes = response.data(using: .utf8) else {
            self.logger.log("fillBuffer", "Can't decode response to byte buffer.")
            throw ResolverErrors.invalidResponse
        }
        var size = rawBytes.count
        //* Check if rawBytes has at least two bytes within  
        if size <= 1 {
            throw ResolverErrors.invalidResponse
        }
        //* Check rawBytes if has even number of bytes within
        if size % 2 != 0 {
            size -= 1
        }
        // Fill buffer
        self.buffer.removeAll()
        var begin = 0
        var end = 2
        for idx in stride(from: 0, to: size, by: 2) {
            begin = idx
            end = idx + 1
            //* Grab the next byte pair from bytes buffer
            let bytePair = String(data: rawBytes.subdata(in: Range(begin...end)), encoding: .utf8) ?? ""
            //* Decode the byte pair and append it to buffer
            guard let parsedHex = ASCIIHelper.hexToInt(bytePair) else { continue }
            buffer.append(parsedHex)
        }
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

    public func getResult() -> String? {
        return self.response
    }

    public func getResultUnit() -> String {
        fatalError("This method should be overridden.")
    }

}
