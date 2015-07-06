//
//  TwitterList.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import SwifteriOS

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

    init(_ json: JSONValue) {
        self.id = json["id_str"].string ?? ""
        self.name = json["name"].string ?? ""
        self.description = json["description"].string ?? ""
        self.subscriberCount = json["subscriber_count"].integer ?? 0
        self.memberCount = json["member_count"].integer ?? 0
        self.following = json["member_count"].boolValue
        self.mode = json["mode"].string ?? ""
        self.createdAt = TwitterDate(json["created_at"].string ?? "")
        self.user = TwitterUser(json["user"])
    }
}
