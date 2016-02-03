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
        case Notifications
        case Favorites
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

    var dictionaryValue: NSDictionary {
        return [
            Constants.type      : type.rawValue,
            Constants.userID    : userID,
            Constants.arguments : arguments
        ]
    }
}
