// Created by AhmedSleem

/**
 * Turns off line-feed.
 *
 */
class LineFeedOffCommand : ObdCommand {

    public override init() {
        super.init("AT L0")
    }

}