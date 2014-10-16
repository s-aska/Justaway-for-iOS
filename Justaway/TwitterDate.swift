import Foundation
import SwifteriOS

class TwitterDateFormatter {
    
    struct Static {
        static let twitter: NSDateFormatter = TwitterDateFormatter.makeTwitter()
        static let absolute: NSDateFormatter = TwitterDateFormatter.makeAbsolute()
    }
    
    private class func makeTwitter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        return formatter
    }
    
    private class func makeAbsolute() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }
    
    class var twitter: NSDateFormatter { return Static.twitter }
    class var absolute: NSDateFormatter { return Static.absolute }
    
}

struct TwitterDate {
    let date: NSDate
    
    init(_ string: String) {
        if let date = TwitterDateFormatter.twitter.dateFromString(string) {
            self.date = date
        } else {
            self.date = NSDate(timeIntervalSince1970: 0)
        }
    }
    
    init(_ date: NSDate) {
        self.date = date
    }
    
    var absoluteString: String {
        return TwitterDateFormatter.absolute.stringFromDate(date)
    }
    
    var relativeString: String {
        let diff = Int(NSDate().timeIntervalSinceDate(date))
        if (diff < 1) {
            return "now";
        } else if (diff < 60) {
            return NSString(format: "%ds", diff)
        } else if (diff < 3600) {
            return NSString(format: "%dm", diff / 60)
        } else if (diff < 86400) {
            return NSString(format: "%dh", diff / 3600)
        } else if (diff < 86400_000) {
            return NSString(format: "%dh", diff / 86400)
        } else {
            return NSString(format: "%dy", diff / (86400 * 365))
        }
    }
}
