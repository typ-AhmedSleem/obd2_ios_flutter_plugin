// Created by AhmedSleem

class SelectProtocolCommand : ObdCommand {

    public override init(obdProtocol: String) {
        super.init("AT SP \(obdProtocol)")
    }

}