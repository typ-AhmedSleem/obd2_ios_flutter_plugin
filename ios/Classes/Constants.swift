import CoreBluetooth

struct MethodChannelsNames {
    public static let BLUE_DEVICES = "BLUE_DEVICES"
    public static let FUEL = "FUEL"
}

struct MethodsNames {
    public static let  SCAN_BLUETOOTH_DEVICES = "scan"
    public static let  CONNECT_ADAPTER = "CONNECT"
    public static let  INIT_ADAPTER = "INIT"
    public static let  GET_FUEL_LEVEL = "GET_LEVEL"
}

struct OBDConstants {
    public static let OBD_ADAPTER_NAME = "KONNWEI"
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
