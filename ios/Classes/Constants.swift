import CoreBluetooth

struct Constants {
    public static let  METHOD_CHANNEL_NAME = "OBD2"
    public static let  INIT_OBD2_METHOD_NAME = "initOBD2"
    public static let  CONNECT_OBD_METHOD_NAME = "connectOBD2"
    public static let  GET_FUEL_LEVEL_METHOD_NAME = "carFuelLevel"

    public static let  INITIAL_RESULT = -1

    public static let  RESULT_CODE_INIT_DONE = -2
    public static let  RESULT_CODE_ERROR = -2
    public static let  RESULT_CODE_FAILED = -3

    public static let  ERROR_STOPPED = -4
    public static let  ERROR_NO_DATA = -5
    public static let  ERROR_UNABLE_TO_CONNECT = -6

    public static let  CMD_PREFIX = ""
    public static let  CMD_ECHO_ON = "AT E1"
    public static let  CMD_ECHO_OFF = "AT E0"
    public static let  CMD_OBD2_IDENTIFIER = "AT @2"
    public static let  CMD_AUTO_FORMATTING_ON = "AT CAF1"
    public static let  CMD_RESPONSES_ON = "AT R1"
    public static let  CMD_GET_FUEL_LEVEL = ""

    public static let  RESPONSE_OK = "OK"
    public static let  RESPONSE_NO_DATA = ""
    public static let  RESPONSE_ERROR = "?"
}

struct OBDConstants {
    public static let OBD_ADAPTER_NAME = "KONNWEI"
}

struct UUIDs {
    // todo: Replace those UUIDs with the real OBD2 adapter ones
	public static let serviceUUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
	public static let charUUID = CBUUID(string: "08590F7E-DB05-467E-8757-72F6FAEB13D4")
}

/**
 * All OBD protocols.
 *
 */
struct ObdProtocols {

    /**
     * Auto select protocol and save.
     */
    public static let AUTO = "0"
    
    /**
     * 41.6 kbaud
     */
    public static let SAE_J1850_PWM = "1"

    /**
     * 10.4 kbaud
     */
    public static let SAE_J1850_VPW = "2"

    /**
     * 5 baud init
     */
    public static let ISO_9141_2 = "3"

    /**
     * 5 baud init
     */
    public static let ISO_14230_4_KWP = "4"

    /**
     * Fast init
     */
    public static let ISO_14230_4_KWP_FAST = "5"

    /**
     * 11 bit ID, 500 kbaud
     */
    public static let ISO_15765_4_CAN = "6"

    /**
     * 29 bit ID, 500 kbaud
     */
    public static let ISO_15765_4_CAN_B = "7"

    /**
     * 11 bit ID, 250 kbaud
     */
    public static let ISO_15765_4_CAN_C = "8"

    /**
     * 29 bit ID, 250 kbaud
     */
    public static let ISO_15765_4_CAN_D = "9"

    /**
     * 29 bit ID, 250 kbaud (user adjustable)
     */
    public static let SAE_J1939_CAN = "A"

    /**
     * 11 bit ID (user adjustable), 125 kbaud (user adjustable)
     */
    public static let USER1_CAN = "B"

    /**
     * 11 bit ID (user adjustable), 50 kbaud (user adjustable)
     */
    public static let USER2_CAN = "C"

}