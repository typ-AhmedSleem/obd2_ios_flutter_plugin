// Created by AhmedSleem

/**
 * As per https://www.elmelectronics.com/help/obd/tips/#327_Commands:
 * <p>
 * If a connection is lost, you will need to tell the ELM327 to ‘close’
 * the current connection, with a Protocol Close command (AT PC).
 * This will ensure that the ELM327 starts from the beginning when
 * the next request is made. This is particularly important for the
 * ISO 9141 and ISO 14230 protocols, as they need to send a special
 * initiation sequence.
 * <p>
 * Once the protocol has been closed, it can be re-opened by making a
 * request such as 01 00 (do not send ATZ or AT SP0, as many do).
 */
class CloseCommand : ObdProtocolCommand {
    
    public init() {
        super.init(cmd: "AT PC")
    }
    
}
