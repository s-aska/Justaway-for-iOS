import Foundation

struct TwitterVia {
    let name: String
    let URL: Foundation.URL?

    struct Static {
        // swiftlint:disable:next force_try
        static let regexp = try! NSRegularExpression(pattern: "<a href=\"(.+)\" rel=\"nofollow\">(.+)</a>",
            options: NSRegularExpression.Options.useUnicodeWordBoundaries.intersection(NSRegularExpression.Options.dotMatchesLineSeparators))
    }

    init(_ source: String) {
        let s = source as NSString
        if let match = Static.regexp.firstMatch(in: source, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: source.utf16.count)) {
            if match.numberOfRanges > 0 {
                self.URL = Foundation.URL(string: s.substring(with: match.rangeAt(1)) as String)
                self.name = s.substring(with: match.rangeAt(2))
                return
            }
        }
        self.URL = nil
        self.name = source
    }

    init(_ dictionary: [String: String]) {
        self.name = dictionary["name"] ?? ""
        self.URL = Foundation.URL(string: dictionary["URL"] ?? "")
    }

    var dictionaryValue: [String: String] {
        return [
            "name": name,
            "URL": URL?.absoluteString ?? ""
        ]
    }
}
