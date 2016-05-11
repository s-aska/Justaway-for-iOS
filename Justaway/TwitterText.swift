//
//  TwitterText.swift
//  Justaway
//
//  Created by Shinichiro Aska on 4/1/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation

// swiftlint:disable:next force_try
let linkDetector = try! NSDataDetector.init(types: NSTextCheckingType.Link.rawValue)

class TwitterText {
    class func count(text: String, hasImage: Bool) -> Int {
        var count = text.characters.count
        let s = text as NSString
        let matches = linkDetector.matchesInString(text, options: [], range: NSRange.init(location: 0, length: text.utf16.count))
        for match in matches {
            let url = s.substringWithRange(match.range) as String
            count = count + 23 - url.characters.count
        }
        if hasImage {
            count = count + 24
        }
        return count
    }
}
