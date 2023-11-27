// Created by AhmedSleem

import Foundation

class ResponsePacket {

    let data: Data

    init(payload data: Data) {
        self.data = data
    }

    convenience init(payload dataString: String) {
        self.init(payload: dataString.data(using: .utf8) ?? Data())
    }

    func decodePayload() -> String {
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func empty() -> ResponsePacket {
        return ResponsePacket(payload: "NO DATA")
    }

}

/**
* Acts like a Queue with a consumer and a guard on accessing packets it holds.
* This class simply has a Queue that holds a fixed size of 'ResponsePackets',
* it also has a 'ResponseConsumer' that pops the most recent a response 
* to the caller that want to consume it.
* 
*/
class ResponseStation : ResponseConsumer {

    //* Runtime
    private let queue: [Data]
    public let maxQueueSize: Int
    public var queueSize: Int {
        get {
            return queue.count
        }
    } 
    private var hasPackets: Bool {
        get { return !queue.isEmpty }
    }

    init(queueSize maxQueueSize: Int = 50) {
        self.maxQueueSize = maxQueueSize
    }

    public func push(packet responsePacket: ResponsePacket) {
        //* Remove the very first packet and push the new one
        if self.queueSize >= self.maxQueueSize {
            self.consumeResponse()
        }
        self.queue.append(responsePacket)
    }

    public func consume() -> ResponsePacket {
        return self.hasPackets ? queue.removeFirst() : ResponsePacket.empty()
    }

}