// Created by AhmedSleem

/**
 * Turn-off echo.
 *
 */
class EchoOffCommand : ObdCommand {

    public override init() {
        super.init("AT E0")
    }

}
