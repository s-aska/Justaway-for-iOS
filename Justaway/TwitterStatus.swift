import UIKit
import SwiftyJSON

class TwitterStatus {

    enum TwitterStatusType {
        case Normal, Favorite, UnFavorite
    }

    let user: TwitterUser
    let statusID: String
    let inReplyToStatusID: String?
    let inReplyToUserID: String?
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
    let quotedStatus: TwitterStatus?
    let event: String?
    let connectionID: String
    let possiblySensitive: Bool

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    init(_ json: JSON, connectionID: String = "") {
        let targetJson = json["target_object"] != nil ? json["target_object"] : json
        let statusJson = targetJson["retweeted_status"] != nil ? targetJson["retweeted_status"] : targetJson
        self.connectionID = connectionID
        self.event = json["event"].string
        self.user = TwitterUser(statusJson["user"])
        self.statusID = statusJson["id_str"].string ?? ""
        self.inReplyToStatusID = statusJson["in_reply_to_status_id_str"].string
        self.inReplyToUserID = statusJson["in_reply_to_user_id_str"].string
        self.createdAt = TwitterDate(statusJson["created_at"].string!)
        self.retweetCount = statusJson["retweet_count"].int ?? 0
        self.favoriteCount = statusJson["favorite_count"].int ?? 0
        self.possiblySensitive = statusJson["possibly_sensitive"].boolValue

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

        self.text = { (urls, media) in
            var text = statusJson["text"].string ?? ""
            text = text.stringByReplacingOccurrencesOfString("&lt;", withString: "<", options: [], range: nil)
            text = text.stringByReplacingOccurrencesOfString("&gt;", withString: ">", options: [], range: nil)
            text = text.stringByReplacingOccurrencesOfString("&amp;", withString: "&", options: [], range: nil)
            for url in urls {
                text = text.stringByReplacingOccurrencesOfString(url.shortURL, withString: url.displayURL, options: NSStringCompareOptions.LiteralSearch, range: nil)
            }
            for media in media {
                text = text.stringByReplacingOccurrencesOfString(media.shortURL, withString: media.displayURL, options: NSStringCompareOptions.LiteralSearch, range: nil)
            }
            return text
        }(self.urls, self.media)

        self.via = TwitterVia(statusJson["source"].string ?? "unknown")

        if json["event"].string == "favorite" || json["event"].string == "favorited_retweet" {
            self.type = .Favorite
            self.actionedBy = TwitterUser(json["source"])
            self.referenceStatusID = nil
        } else if json["event"].string == "unfavorite" {
            self.type = .UnFavorite
            self.actionedBy = TwitterUser(json["source"])
            self.referenceStatusID = nil
        } else if json["event"].string == "retweeted_retweet" {
            self.type = .Normal
            self.actionedBy = TwitterUser(json["source"])
            self.referenceStatusID = targetJson["id_str"].string
        } else if targetJson["retweeted_status"] != nil {
            self.type = .Normal
            self.actionedBy = TwitterUser(targetJson["user"])
            self.referenceStatusID = targetJson["id_str"].string
        } else {
            self.type = .Normal
            self.actionedBy = nil
            self.referenceStatusID = nil
        }

        if statusJson["quoted_status"] != nil {
            self.quotedStatus = TwitterStatus(statusJson["quoted_status"])
        } else {
            self.quotedStatus = nil
        }
    }

    init(_ status: TwitterStatus, type: TwitterStatusType, event: String?, actionedBy: TwitterUser?) {
        self.type = type
        self.event = event
        self.actionedBy = actionedBy
        self.user = status.user
        self.statusID = status.statusID
        self.inReplyToStatusID = status.inReplyToStatusID
        self.inReplyToUserID = status.inReplyToUserID
        self.text = status.text
        self.createdAt = status.createdAt
        self.via = status.via
        self.retweetCount = status.retweetCount
        self.favoriteCount = status.favoriteCount
        self.urls = status.urls
        self.mentions = status.mentions
        self.hashtags = status.hashtags
        self.media = status.media
        self.referenceStatusID = actionedBy != nil ? status.referenceStatusID : nil
        self.quotedStatus = status.quotedStatus
        self.connectionID = status.connectionID
        self.possiblySensitive = status.possiblySensitive
    }

    init(_ dictionary: [String: AnyObject]) {
        self.connectionID = ""
        self.user = TwitterUser(dictionary["user"] as? [String: AnyObject] ?? [:])
        self.statusID = dictionary["statusID"] as? String ?? ""
        self.text = dictionary["text"] as? String ?? ""
        self.createdAt = TwitterDate(NSDate(timeIntervalSince1970: (dictionary["createdAt"] as? NSNumber ?? 0).doubleValue))
        self.retweetCount = dictionary["retweetCount"] as? Int ?? 0
        self.favoriteCount = dictionary["favoriteCount"] as? Int ?? 0
        self.possiblySensitive = dictionary["possiblySensitive"] as? Bool ?? false

        if let urls = dictionary["urls"] as? [[String: String]] {
            self.urls = urls.map({ TwitterURL($0) })
        } else {
            self.urls = [TwitterURL]()
        }

        if let mentions = dictionary["mentions"] as? [[String: AnyObject]] {
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

        self.via = TwitterVia(dictionary["via"] as? [String: String] ?? [:])

        if let actionedBy = dictionary["actionedBy"] as? [String: AnyObject] {
            self.actionedBy = TwitterUser(actionedBy)
        } else {
            self.actionedBy = nil
        }

        if let event = dictionary["event"] as? String {
            self.event = event
            if event == "favorite" || event == "favorited_retweet" {
                self.type = .Favorite
            } else if event == "unfavorite" {
                self.type = .UnFavorite
            } else {
                self.type = .Normal
            }
        } else {
            self.event = nil
            self.type = .Normal
        }

        if let inReplyToStatusID = dictionary["inReplyToStatusID"] as? String {
            self.inReplyToStatusID = inReplyToStatusID
        } else {
            self.inReplyToStatusID = nil
        }

        if let inReplyToUserID = dictionary["inReplyToUserID"] as? String {
            self.inReplyToUserID = inReplyToUserID
        } else {
            self.inReplyToUserID = nil
        }

        if let referenceStatusID = dictionary["referenceStatusID"] as? String {
            self.referenceStatusID = referenceStatusID
        } else {
            self.referenceStatusID = nil
        }

        if let quotedStatus = dictionary["quotedStatus"] as? [String: AnyObject] {
            self.quotedStatus = TwitterStatus(quotedStatus)
        } else {
            self.quotedStatus = nil
        }
    }

    var isActioned: Bool {
        return actionedBy != nil
    }

    var uniqueID: String {
        if let actionedBy = actionedBy, event = event {
            return [statusID, event, actionedBy.userID].joinWithSeparator(":")
        } else if self.inReplyToUserID != nil {
            return [statusID, "reply", user.userID].joinWithSeparator(":")
        } else {
            return referenceOrStatusID
        }
    }

    var referenceOrStatusID: String {
        return referenceStatusID ?? statusID
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
            "via": via.dictionaryValue,
            "possiblySensitive": possiblySensitive
        ]

        if let event = self.event {
            dictionary["event"] = event
        }

        if let actionedBy = self.actionedBy {
            dictionary["actionedBy"] = actionedBy.dictionaryValue
        }

        if let inReplyToStatusID = self.inReplyToStatusID {
            dictionary["inReplyToStatusID"] = inReplyToStatusID
        }

        if let inReplyToUserID = self.inReplyToUserID {
            dictionary["inReplyToUserID"] = inReplyToUserID
        }

        if let referenceStatusID = self.referenceStatusID {
            dictionary["referenceStatusID"] = referenceStatusID
        }

        if let quotedStatus = self.quotedStatus {
            dictionary["quotedStatus"] = quotedStatus.dictionaryValue
        }

        return dictionary
    }
}
