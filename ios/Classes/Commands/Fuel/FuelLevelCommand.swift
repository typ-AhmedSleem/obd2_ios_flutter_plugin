//
//  FuelLevelCommand.swift
//
//  Created by AhmedSleem on 06/11/2023.
//

class FuelLevelCommand : PercentageObdCommand {
    
    public init() {
        super.init(command: "01 2F")
    }

    public override func performCalculations() {
        // ignore first two bytes [hh hh] of the response
        self.percentage = (buffer[2] * 100.0) / 255.0;
    }

    public override func getResultUnit() {
        if self.useImperialUnits {
            return "Litres"
        }else {
            return "Gallons"
        }
    }

}
