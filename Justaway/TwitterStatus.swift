import Foundation
import SwifteriOS

class TwitterStatus {
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
    let isProtected: Bool
    let media: [TwitterMedia]
    let actionedBy: TwitterUser?
    let referenceStatusID: String?
    
    init(_ json: JSONValue) {
        let statusJson = json["retweeted_status"].object != nil ? json["retweeted_status"] : json
        self.user = TwitterUser(statusJson["user"])
        self.statusID = statusJson["id_str"].string ?? ""
        self.text = statusJson["text"].string ?? ""
        self.createdAt = TwitterDate(statusJson["created_at"].string!)
        self.retweetCount = statusJson["retweet_count"].integer ?? 0
        self.favoriteCount = statusJson["favorite_count"].integer ?? 0
        
        self.text = self.text.stringByReplacingOccurrencesOfString("&lt;", withString: "<", options: nil, range: nil)
        self.text = self.text.stringByReplacingOccurrencesOfString("&gt;", withString: ">", options: nil, range: nil)
        self.text = self.text.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: nil, range: nil)
        
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
        
        self.isProtected = statusJson["protected"].boolValue
        
        if let extended_entities = statusJson["entities"]["extended_entities"].array {
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
        }
    }
    
    var isActioned: Bool {
        return self.actionedBy != nil
    }
    
    var uniqueID: String {
        return self.referenceStatusID ?? self.statusID
    }
}
