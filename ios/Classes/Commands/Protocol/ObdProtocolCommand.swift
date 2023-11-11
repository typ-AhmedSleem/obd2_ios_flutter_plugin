// Created by AhmedSleem

class ObdProtocolCommand : ObdCommand {

    init(command: String) {
        super.init(command)
    }

    override func execute(obd: OBD2) {
        // Time the start of execution
        self.timeStart = TimeHelper.currentTimeInMillis()
        // Send the command to peripheral bu calling sendCommand
        self.sendCommand(obd)
        // Time the end of execution
        self.timeEnd = TimeHelper.currentTimeInMillis()
    }

}