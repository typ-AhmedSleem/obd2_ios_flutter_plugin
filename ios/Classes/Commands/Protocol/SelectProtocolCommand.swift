// Created by AhmedSleem

class SelectProtocolCommand : ObdProtocolCommand {
    
    public init(obdProtocol: String) {
        super.init(cmd: "AT SP \(obdProtocol)")
    }
    
}
