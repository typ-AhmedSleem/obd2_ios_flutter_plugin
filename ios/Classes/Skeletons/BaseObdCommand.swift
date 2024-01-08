//
//  BaseObdCommand.swift
//  obd2_flutter_plugin
//
//  Created by Ahmed Sleem on 08/01/2024.
//

protocol BaseObdCommand {
    
    /**
     * Uses bytes available in buffer to perform a suitable sequence of calculations to build the desired result.
     * [SHOULD BE OVERRIDEN]
     */
    func performCalculations() async throws
    
    /**
     *  Returns the formatted result after being calculated.
     *  [performCalculations SHOULD BE CALLED AT LEAST ONCE BEFORE CALLING THIS METHOD]
     */
    func getFormattedResult() -> String
    
    /**
     * Returns the suitable unit for this command.
     * [SHOULD BE OVERRIDEN]
     */
    func getResultUnit() -> String
    
}
