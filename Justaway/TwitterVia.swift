import Foundation
import SwifteriOS

struct TwitterVia {
    let name: String
    let URL: NSURL?
    
    struct Static {
        static let regexp = NSRegularExpression(pattern: "<a href=\"(.+)\" rel=\"nofollow\">(.+)</a>", options: NSRegularExpressionOptions(0), error: nil)!
    }
    
    init(_ source: String) {
        if let match = Static.regexp.firstMatchInString(source, options: NSMatchingOptions(0), range: NSMakeRange(0, countElements(source))) {
            if match.numberOfRanges > 0 {
                self.URL = NSURL(string: (source as NSString).substringWithRange(match.rangeAtIndex(1)) as String)
                self.name = (source as NSString).substringWithRange(match.rangeAtIndex(2))
                return
            }
        }
        self.name = source
    }
}
