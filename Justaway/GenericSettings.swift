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
        static let keychainKey = "GenericSettings"
    }
    
    struct Static {
        static var instance: GenericSettings?
    }
    
    let fontSize: Float
    
    init() {
        self.fontSize = 12.0
    }
    
    init(fontSize: Float) {
        self.fontSize = fontSize
    }
    
    init(_ dictionary: NSDictionary) {
        if let fontSize = dictionary[Constants.fontSize] as? Float {
            self.fontSize = fontSize
        } else {
            self.fontSize = 12.0
        }
    }
    
    var dictionaryValue: NSDictionary {
        return [
            Constants.fontSize: self.fontSize
        ]
    }
    
    class func configure() {
        EventBox.onMainThread(self, name: EventFontSizeApplied) { (n) -> Void in
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
        let genericSettings = GenericSettings(fontSize: fontSize)
        save(genericSettings)
        return genericSettings
    }
}
