//
//  TwitterList.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TwitterList {
    let id: String
    let name: String
    let description: String
    let subscriberCount: Int
    let memberCount: Int
    let mode: String
    let following: Bool
    let user: TwitterUser
    let createdAt: TwitterDate

    init(_ json: JSON) {
        self.id = json["id_str"].string ?? ""
        self.name = json["name"].string ?? ""
        self.description = json["description"].string ?? ""
        self.subscriberCount = json["subscriber_count"].int ?? 0
        self.memberCount = json["member_count"].int ?? 0
        self.following = json["member_count"].boolValue
        self.mode = json["mode"].string ?? ""
        self.createdAt = TwitterDate(json["created_at"].string ?? "")
        self.user = TwitterUser(json["user"])
    }

    init(_ dictionary: [String: AnyObject]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.subscriberCount = dictionary["subscriberCount"] as? Int ?? 0
        self.memberCount = dictionary["memberCount"] as? Int ?? 0
        self.mode = dictionary["mode"] as? String ?? ""
        self.following = dictionary["following"] as? Bool ?? false
        self.user = TwitterUser(dictionary["id"] as? [String: AnyObject] ?? [:])
        self.createdAt = TwitterDate(Date(timeIntervalSince1970: (dictionary["createdAt"] as? NSNumber ?? 0).doubleValue))
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "id": id as AnyObject,
            "name": name as AnyObject,
            "description": description as AnyObject,
            "subscriberCount": subscriberCount as AnyObject,
            "memberCount": memberCount as AnyObject,
            "mode": mode as AnyObject,
            "following": following as AnyObject,
            "user": user.dictionaryValue as AnyObject,
            "createdAt": Int(createdAt.date.timeIntervalSince1970) as AnyObject
        ]
    }
}
