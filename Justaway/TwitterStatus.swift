import Foundation
import SwifteriOS

class TwitterStatus {
    
    enum TwitterStatusType {
        case Normal, Event, Message
    }
    
    let user: TwitterUser
    let statusID: String
    let text: String
    let createdAt: TwitterDate
    let via: TwitterVia
    let retweetCount: Int
    let favoriteCount: Int
    let urls: [TwitterURL]
    let mentions: [TwitterUser]
    let hashtags: [TwitterHashtag]
    let media: [TwitterMedia]
    let actionedBy: TwitterUser?
    let referenceStatusID: String?
    let type: TwitterStatusType
    
    init(_ json: JSONValue) {
        self.type = .Normal
        let statusJson = json["retweeted_status"].object != nil ? json["retweeted_status"] : json
        self.user = TwitterUser(statusJson["user"])
        self.statusID = statusJson["id_str"].string ?? ""
        self.createdAt = TwitterDate(statusJson["created_at"].string!)
        self.retweetCount = statusJson["retweet_count"].integer ?? 0
        self.favoriteCount = statusJson["favorite_count"].integer ?? 0
        
        self.text = {
            var text = statusJson["text"].string ?? ""
            text = text.stringByReplacingOccurrencesOfString("&lt;", withString: "<", options: [], range: nil)
            text = text.stringByReplacingOccurrencesOfString("&gt;", withString: ">", options: [], range: nil)
            text = text.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: [], range: nil)
            return text
        }()
        
        if let urls = statusJson["entities"]["urls"].array {
            self.urls = urls.map { TwitterURL($0) }
        } else {
            self.urls = [TwitterURL]()
        }
        
        if let userMentions = statusJson["entities"]["user_mentions"].array {
            self.mentions = userMentions.map { TwitterUser($0) }
        } else {
            self.mentions = [TwitterUser]()
        }
        
        if let hashtags = statusJson["entities"]["hashtags"].array {
            self.hashtags = hashtags.map { TwitterHashtag($0) }
        } else {
            self.hashtags = [TwitterHashtag]()
        }
        
        if let extended_entities = statusJson["extended_entities"]["media"].array {
            self.media = extended_entities.map { TwitterMedia($0) }
        } else if let media = statusJson["entities"]["media"].array {
            self.media = media.map { TwitterMedia($0) }
        } else {
            self.media = [TwitterMedia]()
        }
        
        self.via = TwitterVia(statusJson["source"].string ?? "unknown")
        
        if json["retweeted_status"].object != nil {
            self.actionedBy = TwitterUser(json["user"])
            self.referenceStatusID = json["id_str"].string
        } else {
            self.actionedBy = nil
            self.referenceStatusID = nil
        }
    }
    
    init(_ dictionary: [String: AnyObject]) {
        self.type = .Normal
        self.user = TwitterUser(dictionary["user"] as? [String: AnyObject] ?? [:])
        self.statusID = dictionary["statusID"] as? String ?? ""
        self.text = dictionary["text"] as? String ?? ""
        self.createdAt = TwitterDate(NSDate(timeIntervalSince1970: (dictionary["createdAt"] as? NSNumber ?? 0).doubleValue))
        self.retweetCount = dictionary["retweetCount"] as? Int ?? 0
        self.favoriteCount = dictionary["favoriteCount"] as? Int ?? 0
        
        if let urls = dictionary["urls"] as? [[String: String]] {
            self.urls = urls.map({ TwitterURL($0) })
        } else {
            self.urls = [TwitterURL]()
        }
        
        if let mentions = dictionary["mentions"] as? [[String: String]] {
            self.mentions = mentions.map({ TwitterUser($0) })
        } else {
            self.mentions = [TwitterUser]()
        }
        
        if let hashtags = dictionary["hashtags"] as? [[String: AnyObject]] {
            self.hashtags = hashtags.map({ TwitterHashtag($0) })
        } else {
            self.hashtags = [TwitterHashtag]()
        }
        
        if let media = dictionary["media"] as? [[String: AnyObject]] {
            self.media = media.map({ TwitterMedia($0) })
        } else {
            self.media = [TwitterMedia]()
        }
        
        self.via = TwitterVia(dictionary["via"] as! [String: String])
        
        if let actionedBy = dictionary["actionedBy"] as? [String: AnyObject] {
            self.actionedBy = TwitterUser(actionedBy)
        } else {
            self.actionedBy = nil
        }
        
        if let referenceStatusID = dictionary["referenceStatusID"] as? String {
            self.referenceStatusID = referenceStatusID
        } else {
            self.referenceStatusID = nil
        }
    }
    
    var isActioned: Bool {
        return self.actionedBy != nil
    }
    
    var uniqueID: String {
        return self.referenceStatusID ?? self.statusID
    }
    
    var statusURL: NSURL {
        return NSURL(string: "https://twitter.com/\(user.screenName)/status/\(statusID)")!
    }
    
    var dictionaryValue: [String: AnyObject] {
        var dictionary: [String: AnyObject] = [
            "user": user.dictionaryValue,
            "statusID": statusID,
            "text": text,
            "createdAt": Int(createdAt.date.timeIntervalSince1970),
            "retweetCount": retweetCount,
            "favoriteCount": favoriteCount,
            "urls": urls.map({ $0.dictionaryValue }),
            "mentions": mentions.map({ $0.dictionaryValue }),
            "hashtags": hashtags.map({ $0.dictionaryValue }),
            "media": media.map({ $0.dictionaryValue }),
            "via": via.dictionaryValue
        ]
        
        if let actionedBy = self.actionedBy {
            dictionary["actionedBy"] = actionedBy.dictionaryValue
        }
        
        if let referenceStatusID = self.referenceStatusID {
            dictionary["referenceStatusID"] = referenceStatusID
        }
        
        return dictionary
    }
}
