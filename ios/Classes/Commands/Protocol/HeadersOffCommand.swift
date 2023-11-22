// Created by AhmedSleem

/**
 * Turn-off headers.
 *
 */
class HeadersOffCommand : ObdProtocolCommand {

    public init() {
        super.init("AT H0")
    }

}
