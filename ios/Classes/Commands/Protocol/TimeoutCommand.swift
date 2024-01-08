// Created by AhmedSleem

/**
 * This will set the value of time in milliseconds (ms) that the OBD interface
 * will wait for a response from the ECU. If exceeds, the response is "NO DATA".
 *
 */
class TimeoutCommand : ObdProtocolCommand {

    init(timeout: Int) {
        super.init(cmd: "AT ST \(String(0xFF & timeout, radix: 16))")
    }

}
