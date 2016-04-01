//
//  TwitterText.swift
//  Justaway
//
//  Created by Shinichiro Aska on 4/1/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation

// swiftlint:disable:next force_try
let urlRegexp = try! NSRegularExpression(pattern: "https?://[0-9a-zA-Z/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+", options: .CaseInsensitive)

class TwitterText {
    class func count(text: String, hasImage: Bool) -> Int {
        var count = text.characters.count
        let s = text as NSString
        let matches = urlRegexp.matchesInString(text, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            let url = s.substringWithRange(match.rangeAtIndex(0)) as String
            let urlCount = url.hasPrefix("https") ? 23 : 22
            count = count + urlCount - url.characters.count
        }
        if hasImage {
            count = count + 23
        }
        return count
    }
}
