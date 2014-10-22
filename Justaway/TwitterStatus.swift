import Foundation
import SwifteriOS

struct TwitterStatus {
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
    
    init(_ json: JSONValue) {
        self.user = TwitterUser(json["user"])
        self.statusID = json["id_str"].string ?? ""
        self.text = json["text"].string ?? ""
        self.createdAt = TwitterDate(json["created_at"].string!)
        self.retweetCount = json["retweet_count"].integer ?? 0
        self.favoriteCount = json["favorite_count"].integer ?? 0
        
        if let urls = json["entities"]["urls"].array {
            self.urls = urls.map { TwitterURL($0) }
        } else {
            self.urls = [TwitterURL]()
        }
        
        if let userMentions = json["entities"]["user_mentions"].array {
            self.mentions = userMentions.map { TwitterUser($0) }
        } else {
            self.mentions = [TwitterUser]()
        }
        
        if let hashtags = json["entities"]["hashtags"].array {
            self.hashtags = hashtags.map { TwitterHashtag($0) }
        } else {
            self.hashtags = [TwitterHashtag]()
        }
        
        self.isProtected = json["protected"].boolValue
        
        if let extended_entities = json["extended_entities"].array {
            self.media = extended_entities.map { TwitterMedia($0) }
        } else if let media = json["media"].array {
            self.media = media.map { TwitterMedia($0) }
        } else {
            self.media = [TwitterMedia]()
        }
        
        self.via = TwitterVia(json["source"].string ?? "unknown")
    }
}
