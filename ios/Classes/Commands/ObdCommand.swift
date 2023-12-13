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
    internal var response : String?
    public var responseDelayInMs : Int
    internal var timeStart : Int64
    internal var timeEnd : Int64
    
    private let MAX_RESPONSE_DELAY = 250

    public init(_ command: String) {
        self.buffer = NSMutableArray()
        self.cmd = command
        self.useImperialUnits = true
        self.response = nil
        self.responseDelayInMs = 0
        self.timeStart = -1
        self.timeEnd = -1
        self.logger = Logger("ObdCommand::\(command)")
//        logger.log("Created command: \(self.cmd)")
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
    private func sendCommand(bm: BluetoothManager) async throws {
        logger.log("Sending command: \(self.cmd)")
        let readyCmd = self.cmd + "\r"
        try await bm.send(dataToSend: readyCmd)
    }
    
    /**
     * Reads the OBD-II response.
     */
    private func readResult(bluetoothManager: BluetoothManager) async throws -> String? {
        await self.readRawBytes(bm: bluetoothManager)
        try await self.checkForErrors()
        try await self.fillBuffer()
        await performCalculations()
        return self.getFormattedResult()
    }
    
    private func readRawBytes(bm bleManager: BluetoothManager) async {
        //* Consume the very first packet on ResponseStation instance
        let packet = bleManager.consumeNextResponse()
        var rawResponse = packet.decodePayload()
        // Remove Searching... from response
        rawResponse = RegexMatcher.replaceInString(pattern: RegexPatterns.SEARCHING_PATTERN, original: rawResponse, replacement: "")
        // Remove '>' from response
        rawResponse = RegexMatcher.replaceInString(pattern: ">", original: rawResponse, replacement: "")
        // Remove whitespaces and escape letters from response
        rawResponse = RegexMatcher.replaceInString(pattern: RegexPatterns.WHITESPACE_PATTERN, original: rawResponse, replacement: "")
        
        self.response = rawResponse
        self.logger.log("readRawBytes: (\(self.response ?? ""))")
    }
    
    public func checkForErrors() async throws {
        if self.response == nil {
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
                self.logger.log("checkForErrors: Check found issue \(String(describing: error)) in response.")
                throw error
            }
            self.logger.log("checkForErrors: Passed '\(String(describing: error))'...")
        }
    }
    
    /**
     * Resolves the rawData of response and fill buffer with valid response bytes
     */
    private func fillBuffer() async throws {
        var response = response ?? ResponsePacket.empty().decodePayload()
        // Remove all whitespaces and line breaks from response
        response = RegexMatcher.replaceInString(pattern: RegexPatterns.WHITESPACE_PATTERN, original: response, replacement: "")
        // Remove BUS INIT from response
        response = RegexMatcher.replaceInString(pattern: RegexPatterns.BUSINIT_PATTERN, original: response, replacement: "")
        // Check whether response has numeric output
        guard RegexMatcher.isMatchingRegex(inputString: response, regexPattern: RegexPatterns.DIGITS_LETTERS_PATTERN) else {
            self.logger.log("fillBuffer: Response is either invalid or contains not numeric values.")
            throw InvalidResponseError()
        }
        // Resolve the response and fill buffer
        guard let rawBytes = response.data(using: .utf8) else {
            self.logger.log("fillBuffer: Can't decode response to byte buffer.")
            throw InvalidResponseError()
        }
        // Check rawBytes if has even number of bytes within
        var size = rawBytes.count
        if size <= 1 {
            throw InvalidResponseError()
        }
        if size % 2 != 0 {
            size -= 1
        }
        // Fill buffer
        self.buffer.removeAllObjects()
        var begin = 0
        var end = 2
        // sample response: 41 0c 00 0d
        for idx in stride(from: 0, to: size, by: 2) {
            begin = idx
            end = idx + 1
            let bytePair = String(data: rawBytes.subdata(in: Range(begin...end)), encoding: .utf8) ?? ""
            // Decode the byte pair and append it to buffer
            let ascii = ASCIIHelper.hexToASCII(hex: bytePair)
            buffer.add(ascii)
        }
        
//        buffer.clear();
//        int begin = 0;
//        int end = 2;
//        while (end <= rawData.length()) {
//            buffer.add(Integer.decode("0x" + rawData.substring(begin, end)));
//            begin = end;
//            end += 2;
//        }
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
        return self.response
    }

    public func getResultUnit() -> String {
       return "?"
    }

}
