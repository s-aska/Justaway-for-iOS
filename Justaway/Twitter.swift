import Foundation
import SwifteriOS

struct TwitterUser {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    init(_ json: JSONValue) {
        self.userID = json["id_str"].string ?? ""
        self.screenName = json["screen_name"].string ?? ""
        self.name = json["name"].string ?? ""
        self.profileImageURL = NSURL(string: json["profile_image_url"].string ?? "")
    }
}

struct TwitterURL {
    let displayURL: String
    let expandedURL: String
    
    init(_ json: JSONValue) {
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
    }
}

struct TwitterMedia {
    let displayURL: String
    let expandedURL: String
    let mediaURL: NSURL
    let height: Int
    let width: Int
    
    init(_ json: JSONValue) {
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
        self.mediaURL = NSURL(string: json["media_url"].string ?? "")
        self.height = json["sizes"]["large"]["h"].integer ?? 0
        self.width = json["sizes"]["large"]["w"].integer ?? 0
    }
}

struct TwitterStatus {
    let user: TwitterUser
    let statusID: String
    let text: String
    let createdAt: NSDate
    let clientName: String
    let retweetCount: Int
    let favoriteCount: Int
    let urls: [TwitterURL]
    let userMentions: [String]
    let hashtags: [String]
    let isProtected: Bool
    let media: [TwitterMedia]
    
    init(_ json: JSONValue) {
        println(json)
        self.user = TwitterUser(json["user"])
        self.statusID = json["id_str"].string ?? ""
        self.text = json["text"].string ?? ""
        self.createdAt = TwitterDate.dateFromString(json["created_at"].string!)
        self.retweetCount = json["retweet_count"].integer ?? 0
        self.favoriteCount = json["favorite_count"].integer ?? 0
        
        if let urls = json["entities"]["urls"].array {
            self.urls = urls.map { TwitterURL($0) }
        } else {
            self.urls = [TwitterURL]()
        }
        
        if let userMentions = json["entities"]["user_mentions"].array {
            self.userMentions = userMentions.map { $0.string! }
        } else {
            self.userMentions = [String]()
        }
        
        if let hashtags = json["entities"]["hashtags"].array {
            self.hashtags = hashtags.map { $0.string! }
        } else {
            self.hashtags = [String]()
        }
        
        self.isProtected = json["protected"].boolValue
        
        if let extended_entities = json["extended_entities"].array {
            self.media = extended_entities.map { TwitterMedia($0) }
        } else if let media = json["media"].array {
            self.media = media.map { TwitterMedia($0) }
        } else {
            self.media = [TwitterMedia]()
        }
        
        self.clientName = TwitterVia.clientName(json["source"].string ?? "unknown")
    }
}

let failureHandler = { (error: NSError) -> Void in
    NSLog("%@", error.localizedDescription)
}

class Twitter {
    
    // MARK: - Singleton
    
    struct Static {
        static let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
    }
    
    class var swifter : Swifter { return Static.swifter }
    
    // MARK: - Class Methods
    
    class func refreshAccounts(newAccounts: [Account], successHandler: (Void -> Void)) {
        var accounts = [Account]()
        var current = 0
        
        if let accountSettings = AccountSettingsStore.get() {
            
            // Merge accounts and newAccounts
            var newAccountMap = [String: Account]()
            for newAccount in newAccounts {
                newAccountMap[newAccount.userID] = newAccount
            }
            
            accounts = accountSettings.accounts.map({ newAccountMap.removeValueForKey($0.userID) ?? $0 })
            
            for newAccount in newAccountMap.values {
                accounts.insert(newAccount, atIndex: 0)
            }
            
            // Update current index
            let currentUserID = accountSettings.account().userID
            for i in 0 ... accounts.count {
                if accounts[i].userID == currentUserID {
                    current = i
                    break
                }
            }
            
            // Update credential from current account
            swifter.client.credential = accountSettings.account().credential
        } else if newAccounts.count > 0 {
            
            // Merge accounts and newAccounts
            accounts = newAccounts
            
            // Update credential from newAccounts
            swifter.client.credential = accounts[0].credential
        } else {
            return
        }
        
        let userIDs = accounts.map({ $0.userID.toInt()! })
        
        let success :(([JSONValue]?) -> Void) = { (rows: [JSONValue]?) in
            
            // Convert JSONValue
            var userDirectory = [String: TwitterUser]()
            for row in rows! {
                let user = TwitterUser(row)
                userDirectory[user.userID] = user
            }
            
            // Update accounts information
            accounts = accounts.map({ (account: Account) in
                if let user = userDirectory[account.userID] {
                    return Account(
                        credential: account.credential,
                        userID: user.userID,
                        screenName: user.screenName,
                        name: user.name,
                        profileImageURL: user.profileImageURL)
                } else {
                    return account
                }
            })
            
            // Save Device
            AccountSettingsStore.save(AccountSettings(current: current, accounts: accounts))
            
            successHandler()
        }
        
        swifter.getUsersLookupWithUserIDs(userIDs, includeEntities: false, success: success, failure: failureHandler)
    }
    
    class func getHomeTimeline(successHandler: ([TwitterStatus]) -> Void) {
        if let account = AccountSettingsStore.get() {
            swifter.client.credential = account.account().credential
            let success = { (statuses: [JSONValue]?) -> Void in
                if statuses != nil {
                    successHandler(statuses!.map { TwitterStatus($0) })
                }
            }
            let failure = failureHandler
            swifter.getStatusesHomeTimelineWithCount(20, sinceID: nil, maxID: nil, trimUser: nil, contributorDetails: nil, includeEntities: false, success: success, failure: failure)
        }
    }
    
}

class TwitterDate {
    
    struct Static {
        static let twitterFormatter: NSDateFormatter = TwitterDate.makeTwitterFormatter()
        static let absoluteFormatter: NSDateFormatter = TwitterDate.makeAbsoluteFormatter()
    }
    
    private class func makeTwitterFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        formatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        return formatter
    }
    
    private class func makeAbsoluteFormatter() -> NSDateFormatter {
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.calendar = NSCalendar(calendarIdentifier: NSGregorianCalendar)
        formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return formatter
    }
    
    class func dateFromString(createdAt: String) -> NSDate {
        return Static.twitterFormatter.dateFromString(createdAt)!
    }
    
    class func absolute(date: NSDate) -> String {
        return Static.absoluteFormatter.stringFromDate(date)
    }
    
    class func relative(date: NSDate) -> String {
        let diff = Int(NSDate().timeIntervalSinceDate(date))
        if (diff < 1) {
            return "now";
        } else if (diff < 60) {
            return NSString(format: "%ds", diff)
        } else if (diff < 3600) {
            return NSString(format: "%dm", diff / 60)
        } else if (diff < 86400) {
            return NSString(format: "%dh", diff / 3600)
        } else {
            return NSString(format: "%dd", diff / 86400)
        }
    }
    
}

class TwitterVia {
    
    struct Static {
        static let regexp = NSRegularExpression(pattern: "rel=\"nofollow\">(.+)</a>", options: NSRegularExpressionOptions(0), error: nil)
    }
    
    class func clientName(source: String) -> String {
        if let match = Static.regexp.firstMatchInString(source, options: NSMatchingOptions(0), range: NSMakeRange(0, countElements(source))) {
            if match.numberOfRanges > 0 {
                return (source as NSString).substringWithRange(match.rangeAtIndex(1))
            }
        }
        return source
    }
    
}
