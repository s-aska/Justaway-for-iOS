//
//  MainMenuSettings.swift
//  Justaway
//
//  Created by Shinichiro Aska on 10/19/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import EventBox
import KeyClip

class MainMenu {
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

    init(_ dictionary: [String: AnyObject]) {
        self.type = Type(rawValue: (dictionary[Constants.type] as? String) ?? "")!
        self.userID = (dictionary[Constants.userID] as? String) ?? ""
        self.arguments = (dictionary[Constants.arguments] as? NSDictionary) ?? NSDictionary()
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            Constants.type      : type.rawValue,
            Constants.userID    : userID,
            Constants.arguments : arguments
        ]
    }
}

class MainMenuSettings {

    struct Constants {
        static let menus = "menus"
        static let keychainKey = "MainMenuSettings"
    }

    struct Static {
        static var instance: MainMenuSettings?
    }

    let menus: [MainMenu]

    init() {
        self.menus = [MainMenu]()
    }

    init(menus: [MainMenu]) {
        self.menus = menus
    }

    init(_ dictionary: NSDictionary) {
        if let menus = dictionary[Constants.menus] as? [[String: AnyObject]] {
            self.menus = menus.map({ MainMenu($0) })
        } else {
            self.menus = [MainMenu]()
        }
    }

    var dictionaryValue: NSDictionary {
        return [
            Constants.menus : self.menus
        ]
    }

    class func configure() {
    }

    class func get() -> MainMenuSettings {
        return Static.instance ?? load()
    }

    class func load() -> MainMenuSettings {
        if let data = KeyClip.load(Constants.keychainKey) as NSDictionary? {
            let mainMenuSettings = MainMenuSettings(data)
            Static.instance = mainMenuSettings
            return mainMenuSettings
        } else {
            if let accountSettings = AccountSettingsStore.get() {
                var menus = [MainMenu]()
                for account in accountSettings.accounts {
                    menus.append(MainMenu(type: .HomeTimline, userID: account.userID, arguments: [:]))
                    menus.append(MainMenu(type: .Notifications, userID: account.userID, arguments: [:]))
                    menus.append(MainMenu(type: .Favorites, userID: account.userID, arguments: [:]))
                }
                let mainMenuSettings = MainMenuSettings(menus: menus)
                MainMenuSettings.save(mainMenuSettings)
                return mainMenuSettings
            } else {
                return MainMenuSettings()
            }
        }
    }

    class func save(mainMenuSettings: MainMenuSettings) -> Bool {
        Static.instance = mainMenuSettings
        return KeyClip.save(Constants.keychainKey, dictionary: mainMenuSettings.dictionaryValue)
    }
}
