//
//  CommonErrors.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

// todo: Use enum for sub errors below instead of declared classes

class AbstractCallError : Error { }

class NotImplementedError : Error { }

class CommandExecutionError : Error { }

class CantConnectError : Error { }

enum ConnectionErrors: Error {
    case cantConnectError
    case deviceNotFoundError
    case deviceDisconnectedError
}

enum ResolverErrors: Error {
    case invalidBufferContent
    case invalidResponse
    case emptyResponse
}

enum CommonErrors: Error {
    case abstractCallError
    case notImplementedError
}

enum CommandErrors: Error {
    case cantConnectError
    case commandExecutionError(String)
}
