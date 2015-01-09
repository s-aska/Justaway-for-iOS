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
        if let match = Static.regexp.firstMatchInString(source, options: NSMatchingOptions(0), range: NSMakeRange(0, source.utf16Count)) {
            if match.numberOfRanges > 0 {
                self.URL = NSURL(string: (source as NSString).substringWithRange(match.rangeAtIndex(1)) as String)
                self.name = (source as NSString).substringWithRange(match.rangeAtIndex(2))
                return
            }
        }
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
