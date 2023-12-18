// Created by AhmedSleem

import Foundation

class Logger {

    private let TAG : String
    private var lastSubTag: String

    public required init(_ tag: String) {
        self.TAG = tag
        self.lastSubTag = ""
    }

    public func log(_ msg: String?) {
        guard let msg = msg else { return }
        print("[\(self.TAG)]: \(msg).")
    }

    public func log(_ subTag: String, _ msg: String) {
        var message = "[\(self.TAG):\(subTag)] => \(msg)."
        if self.lastSubTag !=  subTag {
            message = "\n" + message
            self.lastSubTag = subTag
        }
        print(message)
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

    public static func replaceInString(pattern: String, original: String, replacement: String) -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            return regex.stringByReplacingMatches(
                in: original,
                options: [],
                range: NSRange(original.startIndex..., in: original),
                withTemplate: replacement
            )
        } catch {
            print("Error happened while replacing in string. Reason: \(error)")
            return original
        }
    }

}

class RegexPatterns {

    public static let WHITESPACE_PATTERN = "(\\s)|(>)"
    public static let BUSINIT_PATTERN = "(BUS INIT)|(BUSINIT)|(\\.)"
    public static let SEARCHING_PATTERN = "SEARCHING"
    public static let DIGITS_LETTERS_PATTERN = "([0-9A-F])+"

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

class ASCIIHelper {

    public static func intToASCII(_ byte: Int) -> Character? {
        let scalar = UnicodeScalar(byte)
        guard let scalar = scalar else { return nil }
        return Character(scalar)
    }

    public static func hexToInt(_ bytes: String) -> Int? {
        if let integerValue = Int(bytes, radix: 16) {
            return integerValue
        } else {
            print("Can't decode hex '\(bytes)' to int")
            return nil
        }
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
