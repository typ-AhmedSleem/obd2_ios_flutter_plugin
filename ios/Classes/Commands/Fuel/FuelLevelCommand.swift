//
//  FuelLevelCommand.swift
//
//  Created by AhmedSleem on 06/11/2023.
//

class FuelLevelCommand : PercentageObdCommand {
    
    public init() {
        super.init("01 2F")
    }

    public convenience init(delay: Int) {
        self.init()
        self.responseDelayInMs = delay
    }

    func performCalculations() throws {
        self.logger.log("performCalculations", "Bytes available in buffer[\(self.buffer)]")
        // ignore first two bytes [hh hh] of the response
        if buffer.count >= 3 {
            self.percentage = (Double(buffer[2]) * 100.0) / 255.0;
        } else {
            throw ResolverErrors.invalidBufferContent
        }
    }

}
