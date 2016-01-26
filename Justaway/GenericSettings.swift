//
//  GenericSettings.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/10/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip
import EventBox

class GenericSettings {

    struct Constants {
        static let fontSize = "font_size"
        static let disableSleep = "disable_sleep"
        static let keychainKey = "GenericSettings"
    }

    struct Static {
        static var instance: GenericSettings?
    }

    let fontSize: Float
    let disableSleep: Bool

    init() {
        self.fontSize = 12.0
        self.disableSleep = false
    }

    init(fontSize: Float, disableSleep: Bool) {
        self.fontSize = fontSize
        self.disableSleep = disableSleep
    }

    init(_ dictionary: NSDictionary) {
        if let fontSize = dictionary[Constants.fontSize] as? Float {
            self.fontSize = fontSize
        } else {
            self.fontSize = 12.0
        }
        if let disableSleep = dictionary[Constants.disableSleep] as? Bool {
            self.disableSleep = disableSleep
        } else {
            self.disableSleep = false
        }
    }

    var dictionaryValue: NSDictionary {
        return [
            Constants.fontSize    : self.fontSize,
            Constants.disableSleep: self.disableSleep
        ]
    }

    class func configure() {
        EventBox.onMainThread(self, name: eventFontSizeApplied) { (n) -> Void in
            if let fontSize = n.userInfo?["fontSize"] as? NSNumber {
                GenericSettings.update(fontSize.floatValue)
            }
        }
    }

    class func get() -> GenericSettings {
        return Static.instance ?? load()
    }

    class func load() -> GenericSettings {
        if let data = KeyClip.load(Constants.keychainKey) as NSDictionary? {
            let genericSettings = GenericSettings(data)
            Static.instance = genericSettings
            return genericSettings
        } else {
            return GenericSettings()
        }
    }

    class func save(genericSettings: GenericSettings) -> Bool {
        Static.instance = genericSettings
        return KeyClip.save(Constants.keychainKey, dictionary: genericSettings.dictionaryValue)
    }

    class func update(fontSize: Float) -> GenericSettings {
        let currentSettings = get()
        let updatedSettings = GenericSettings(fontSize: fontSize, disableSleep: currentSettings.disableSleep)
        save(updatedSettings)
        return updatedSettings
    }

    class func update(disableSleep: Bool) -> GenericSettings {
        let currentSettings = get()
        let updatedSettings = GenericSettings(fontSize: currentSettings.fontSize, disableSleep: disableSleep)
        save(updatedSettings)
        return updatedSettings
    }
}
