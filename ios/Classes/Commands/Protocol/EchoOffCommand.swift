// Created by AhmedSleem

/**
 * Turn-off echo.
 *
 */
class EchoOffCommand : ObdProtocolCommand {
    
    public init() {
        super.init(cmd: "AT E0")
    }
    
}
