//
//  FuelLevelCommand.swift
//
//  Created by AhmedSleem on 06/11/2023.
//

class FuelLevelCommand : PercentageObdCommand {
    
    public init(delay: Int) {
        super.init(cmd: "01 2F", delay: delay)
    }
    
}
