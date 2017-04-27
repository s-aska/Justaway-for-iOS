import Foundation

class TwitterDateFormatter {

    struct Static {
        static let twitter: DateFormatter = TwitterDateFormatter.makeTwitter()
        static let absolute: DateFormatter = TwitterDateFormatter.makeAbsolute()
    }

    fileprivate class func makeTwitter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        return formatter
    }

    fileprivate class func makeAbsolute() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }

    class var twitter: DateFormatter { return Static.twitter }
    class var absolute: DateFormatter { return Static.absolute }

}

struct TwitterDate {
    let date: Date

    init(_ string: String) {
        if let date = TwitterDateFormatter.twitter.date(from: string) {
            self.date = date
        } else {
            self.date = Date(timeIntervalSince1970: 0)
        }
    }

    init(_ date: Date) {
        self.date = date
    }

    var absoluteString: String {
        return TwitterDateFormatter.absolute.string(from: date)
    }

    var relativeString: String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 1 {
            return "now"
        } else if diff < 60 {
            return NSString(format: "%ds", diff) as String
        } else if diff < 3600 {
            return NSString(format: "%dm", diff / 60) as String
        } else if diff < 86400 {
            return NSString(format: "%dh", diff / 3600) as String
        } else if diff < 86400_000 {
            return NSString(format: "%dd", diff / 86400) as String
        } else {
            return NSString(format: "%dy", diff / (86400 * 365)) as String
        }
    }
}
