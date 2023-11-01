
class Constants {
    public let METHOD_CHANNEL_NAME = "OBD2"
    public let INIT_OBD2_METHOD_NAME = "initOBD2"
    public let CONNECT_OBD_METHOD_NAME = "connectOBD2"
    public let GET_FUEL_LEVEL_METHOD_NAME = "carFuelLevel"

    public let INITIAL_RESULT = -1

    public let RESULT_CODE_INIT_DONE = -2
    public let RESULT_CODE_ERROR = -2
    public let RESULT_CODE_FAILED = -3

    public let ERROR_STOPPED = -4
    public let ERROR_NO_DATA = -5
    public let ERROR_UNABLE_TO_CONNECT = -6

    public let CMD_PREFIX = ""
    public let CMD_ECHO_ON = "AT E1"
    public let CMD_ECHO_OFF = "AT E0"
    public let CMD_OBD2_IDENTIFIER = "AT @2"
    public let CMD_AUTO_FORMATTING_ON = "AT CAF1"
    public let CMD_RESPONSES_ON = "AT R1"
    public let CMD_GET_FUEL_LEVEL = ""

    public let RESPONSE_OK = "OK"
    public let RESPONSE_NO_DATA = ""
    public let RESPONSE_ERROR = "?"
}