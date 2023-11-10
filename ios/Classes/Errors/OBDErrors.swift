//
//  OBDErrors.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

class ResponseError : Error{
    
    public let code : Int
    public let message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
}

class ConnectionLostError : ResponseError {
    init() {
        super.init(code: 401, message: "Connection with OBD was lost.")
    }
}

class NoDataError : ResponseError {
    init() {
        super.init(code: 404, message: "OBD has sent NO-DATA packet")
    }
}

class TimeoutError : ResponseError {
    init() {
        super.init(code: 402, message: "Timeout while doing current operation.")
    }
}

class BusBusyError : ResponseError {
    init() {
        super.init(code: 403, message: "OBD is currently busy processing current request. Please wait until operation is complete or request timeout happens.")
    }
}

class InvalidResponseError : ResponseError {
    init() {
        super.init(code: 405, message: "Received invalid non-numeric response from the OBD.")
    }
}

class UnableToConnectError : ResponseError {
    init() {
        super.init(code: 406, message: "Unable to connect to the OBD adapter. Try again later.")
    }
}

class UnSupportedCommandError : ResponseError {
    init() {
        super.init(code: 407, message: "Unsupported command you are trying to send.")
    }
}
