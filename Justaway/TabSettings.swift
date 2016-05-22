//
//  TabSettings.swift
//  Justaway
//
//  Created by Shinichiro Aska on 10/19/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import EventBox
import KeyClip

class Tab {
    struct Constants {
        static let type = "type"
        static let userID = "user_id"
        static let arguments = "arguments"
    }

    enum Type: String {
        case HomeTimline
        case UserTimline
        case Mentions
        case Notifications
        case Favorites
        case Searches
        case Lists
        case Messages
    }

    let type: Type
    let userID: String
    let arguments: NSDictionary

    init(type: Type, userID: String, arguments: NSDictionary) {
        self.type = type
        self.userID = userID
        self.arguments = arguments
    }

    init(_ dictionary: NSDictionary) {
        self.type = Type(rawValue: (dictionary[Constants.type] as? String) ?? "")!
        self.userID = (dictionary[Constants.userID] as? String) ?? ""
        self.arguments = (dictionary[Constants.arguments] as? NSDictionary) ?? NSDictionary()
    }

    init(userID: String, keyword: String) {
        self.type = .Searches
        self.userID = userID
        self.arguments = ["keyword": keyword]
    }

    init(userID: String, user: TwitterUser) {
        self.type = .UserTimline
        self.userID = userID
        self.arguments = ["user": user.dictionaryValue]
    }

    init(userID: String, list: TwitterList) {
        self.type = .Lists
        self.userID = userID
        self.arguments = ["list": list.dictionaryValue]
    }

    var keyword: String {
        return self.arguments["keyword"] as? String ?? "-"
    }

    var user: TwitterUser {
        return TwitterUser(self.arguments["user"] as? [String: AnyObject] ?? [:])
    }

    var list: TwitterList {
        return TwitterList(self.arguments["list"] as? [String: AnyObject] ?? [:])
    }

    var dictionaryValue: NSDictionary {
        return [
            Constants.type      : type.rawValue,
            Constants.userID    : userID,
            Constants.arguments : arguments
        ]
    }
}
