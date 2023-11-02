// Created by AhmedSleem

class Logger {

    private let TAG : String

    public required init(tag: String) {
        self.TAG = tag
    }

    public func log(msg: Any?) {
        if msg == nil {
            return
        }
        print("[\(self.TAG)]: \(msg)")
    }

    public static func log(tag: String, msg: Any) {
        print("[\(tag)]: \(msg)")
    }

}