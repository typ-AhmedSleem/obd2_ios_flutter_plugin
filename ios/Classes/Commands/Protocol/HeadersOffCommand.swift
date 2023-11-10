// Created by AhmedSleem

/**
 * Turn-off headers.
 *
 */
class HeadersOffCommand : ObdCommand {

    public override init() {
        super.init("AT H0")
    }

}