// Created by AhmedSleem

/**
 * Turns off line-feed.
 *
 */
class LineFeedOffCommand : ObdProtocolCommand {

    public init() {
        super.init("AT L0")
    }

}
