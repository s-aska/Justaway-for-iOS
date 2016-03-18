//
//  TwitterMessage.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/16/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TwitterMessage {
    let id: String
    let text: String
    let createdAt: TwitterDate
    let recipient: TwitterUser
    let sender: TwitterUser
    let urls: [TwitterURL]
    let mentions: [TwitterUser]
    let hashtags: [TwitterHashtag]
    let media: [TwitterMedia]

    init(_ json: JSON) {
        self.id = json["id_str"].string ?? ""
        self.text = json["text"].string ?? ""
        self.createdAt = TwitterDate(json["created_at"].string!)
        self.recipient = TwitterUser(json["recipient"])
        self.sender = TwitterUser(json["sender"])

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

        if let extended_entities = json["extended_entities"]["media"].array {
            self.media = extended_entities.map { TwitterMedia($0) }
        } else if let media = json["entities"]["media"].array {
            self.media = media.map { TwitterMedia($0) }
        } else {
            self.media = [TwitterMedia]()
        }
    }

    init(_ dictionary: [String: AnyObject]) {
        self.id = dictionary["id"] as? String ?? ""
        self.text = dictionary["text"] as? String ?? ""
        self.createdAt = TwitterDate(NSDate(timeIntervalSince1970: (dictionary["createdAt"] as? NSNumber ?? 0).doubleValue))
        self.recipient = TwitterUser(dictionary["recipient"] as? [String: AnyObject] ?? [:])
        self.sender = TwitterUser(dictionary["sender"] as? [String: AnyObject] ?? [:])

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
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "id": id,
            "text": text,
            "createdAt": Int(createdAt.date.timeIntervalSince1970),
            "recipient": recipient.dictionaryValue,
            "sender": sender.dictionaryValue,
            "urls": urls.map({ $0.dictionaryValue }),
            "mentions": mentions.map({ $0.dictionaryValue }),
            "hashtags": hashtags.map({ $0.dictionaryValue }),
            "media": media.map({ $0.dictionaryValue })
        ]
    }
}
