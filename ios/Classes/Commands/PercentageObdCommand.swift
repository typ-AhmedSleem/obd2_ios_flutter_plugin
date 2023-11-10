//
//  PercentageObdCommand.swift
//  obd2
//
//  Created by AhmedSleem on 06/11/2023.
//

import Foundation

open class PercentageObdCommand : ObdCommand {
    
    private var percentage: Double = 0.0

    public override init(command: String) {
        super.init(command: command)
    }

    public override func performCalculations() {
        // ignore first two bytes [hh hh] of the response
        self.percentage = (buffer[2] * 100.0) / 255.0;
    }

    public override func getFormattedResult() -> String {
        return "\(self.percentage) \(self.getResultUnit())"
    }

    public override func getResultUnit() -> String {
        return "%"
    }

    public func getPercentage() -> Double {
        return self.percentage
    }

}
