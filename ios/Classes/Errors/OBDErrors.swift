//
//  OBDErrors.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

class ResponseError : Error {

    var message: String
    var response: String
    var command: String = "NO_CMD"
    var matchRegex: Bool

    init(message: String, matchRegex:Bool) {
        self.message = message
        self.matchRegex = matchRegex
    }

    convenience init(message: String) {
        self.init(message: message, matchRegex: false)
    }

    public static func clean(content: String?) -> String {
        return content == nil ? "" : content.replacingOccurrences(of: "\\s", with: "").uppercased()
    }

    public func isError(response: String) -> Bool{
        self.response = response
        if self.matchRegex {
            return RegexMatcher.isMatchingRegex(inputString: clean(self.response), regexPattern: clean(self.message))
        } else {
            return clean(self.response).contains(self.message)
        }
    }

    public func setCommand(command: String) {
        self.command = command
    }

    public func getPrintableErrorMessage() {
        return "Error running \(self.command), response: \(self.response)"
    }

}

/**
 * Thrown when there is a "NO DATA" message.
 *
 */
class NoDataError : ResponseError {
    init() {
        super.init(message: "NO DATA")
    }
}

/**
 * Thrown when there is a "BUS INIT... ERROR" message
 *
 */
class BusInitError : ResponseError {
    init() {
        super.init(message: "BUS INIT... ERROR")
    }
}

/**
 * Thrown when there is a "?" message.
 *
 */
class MisunderstoodCommandError : ResponseError {
    init() {
        super.init(message: "?")
    }
}

/**
 * Thrown when there are no numbers in the response and they are expected
 *
 */
class InvalidResponseError : ResponseError {
    init() {
        super.init(message: "Invalid response received")
    }
}

/**
 * Sent when there is a "STOPPED" message.
 *
 */
class StoppedError : ResponseError {
    init() {
        super.init(message: "STOPPED")
    }
}

/**
 * Thrown when there is a "UNABLE TO CONNECT" message.
 *
 */
class UnableToConnectError : ResponseError {
    init() {
        super.init(message: "UNABLE TO CONNECT")
    }
}

/**
 * Thrown when there is "ERROR" in the response
 *
 */
class UnknownError : ResponseError {
    init() {
        super.init(message: "ERROR")
    }
}

/**
 * Thrown when there is a "?" message as result of sending an unsupported command to the OBD
 *
 */
class UnSupportedCommandError : ResponseError {
    init() {
        super.init(message: "7F 0[0-A] 1[1-2]", matchRegex: true)
    }
}
