//
//  PercentageObdCommand.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

import Foundation

open class PercentageObdCommand : ObdCommand {
    
    var percentage: Double = 0.0

    public override init(_ command: String) {
        super.init(command)
    }

    override func performCalculations() async {
        // ignore first two bytes [hh hh] of the response
        self.percentage = (buffer[2] as! Double * 100.0) / 255.0;
    }

    public override func getFormattedResult() -> String {
        return "\(String(format: "%.1f", self.percentage))\(self.getResultUnit())"
    }

    public override func getResultUnit() -> String {
        return "%"
    }

    public func getPercentage() -> Double {
        return self.percentage
    }

}
