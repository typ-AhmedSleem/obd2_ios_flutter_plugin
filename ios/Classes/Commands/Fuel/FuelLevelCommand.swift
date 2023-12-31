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

    public override func performCalculations() async {
        // ignore first two bytes [hh hh] of the response
        if buffer.count >= 3 {
            self.percentage = (buffer[2] as! Double * 100.0) / 255.0;
        } else {
            self.percentage = 0.0
        }
    }

//    public override func getResultUnit() -> String {
//        if self.useImperialUnits {
//            return "Litres"
//        }else {
//            return "Gallons"
//        }
//    }

}
