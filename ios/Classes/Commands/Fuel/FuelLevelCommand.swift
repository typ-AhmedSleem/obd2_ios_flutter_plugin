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
    
}
