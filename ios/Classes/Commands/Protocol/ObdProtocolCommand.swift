// Created by AhmedSleem

class ObdProtocolCommand : ObdCommand {
    
    public init(cmd command: String) {
        super.init(cmd: command, delay: 25)
    }
    
}
