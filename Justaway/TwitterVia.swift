import Foundation
import SwifteriOS

struct TwitterVia {
    let name: String
    let URL: NSURL?
    
    struct Static {
        static let regexp = NSRegularExpression(pattern: "<a href=\"(.+)\" rel=\"nofollow\">(.+)</a>",
            options: NSRegularExpressionOptions.UseUnicodeWordBoundaries & NSRegularExpressionOptions.DotMatchesLineSeparators,
            error: nil)!
    }
    
    init(_ source: String) {
        let s = source as NSString
        if let match = Static.regexp.firstMatchInString(source, options: NSMatchingOptions(0), range: NSMakeRange(0, count(source.utf16))) {
            if match.numberOfRanges > 0 {
                self.URL = NSURL(string: s.substringWithRange(match.rangeAtIndex(1)) as String)
                self.name = s.substringWithRange(match.rangeAtIndex(2))
                return
            }
        }
        self.URL = nil
        self.name = source
    }
    
    init(_ dictionary: [String: String]) {
        self.name = dictionary["name"] ?? ""
        self.URL = NSURL(string: dictionary["URL"] ?? "")
    }
    
    var dictionaryValue: [String: String] {
        return [
            "name": name,
            "URL": URL?.absoluteString ?? ""
        ]
    }
}
