//
//  TwitterMessage.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/16/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import SwiftyJSON

class TwitterMessage {
    let id: String
    let text: String
    let createdAt: TwitterDate
    let recipient: TwitterUser
    let sender: TwitterUser
    let urls: [TwitterURL]
    let mentions: [TwitterUser]
    let hashtags: [TwitterHashtag]
    let media: [TwitterMedia]
    let ownerID: String

    init(_ json: JSON, ownerID: String) {
        self.ownerID = ownerID
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

    init(_ dictionary: [String: AnyObject], ownerID: String) {
        self.ownerID = ownerID
        self.id = dictionary["id"] as? String ?? ""
        self.text = dictionary["text"] as? String ?? ""
        self.createdAt = TwitterDate(Date(timeIntervalSince1970: (dictionary["createdAt"] as? NSNumber ?? 0).doubleValue))
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

    var collocutor: TwitterUser {
        return ownerID == sender.userID ? recipient : sender
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "id": id as AnyObject,
            "text": text as AnyObject,
            "createdAt": Int(createdAt.date.timeIntervalSince1970) as AnyObject,
            "recipient": recipient.dictionaryValue as AnyObject,
            "sender": sender.dictionaryValue as AnyObject,
            "urls": urls.map({ $0.dictionaryValue }) as AnyObject,
            "mentions": mentions.map({ $0.dictionaryValue }) as AnyObject,
            "hashtags": hashtags.map({ $0.dictionaryValue }) as AnyObject,
            "media": media.map({ $0.dictionaryValue }) as AnyObject
        ]
    }
}
