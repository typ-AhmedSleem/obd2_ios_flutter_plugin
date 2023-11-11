// Created by AhmedSleem

import Foundation

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

class RegexMatcher {

    public static func isMatchingRegex(inputString: String, regexPattern: String) -> Bool{
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: inputString.utf16.count)
            return regex.firstMatch(in: inputString, options: [], range: range) != nil
        } catch {
            print("Error happened while creating RegEx: \(error)")
            return false
        }
    }

}

class TimeHelper {

    public static func currentTimeInMillis() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000)
    }

}

class JSONHelper {

    public static func serializeDictionary(dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            return nil
        }
        return nil
    }

}

extension [String: String] {   

    /**
    * Ext function that serializes the calling dictionary into JSON String
    */
    public func serializeToJSON() -> String?{
        return JSONHelper.serializeDictionary(dictionary: self)
    }
    
}