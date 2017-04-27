//
//  TwitterText.swift
//  Justaway
//
//  Created by Shinichiro Aska on 4/1/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation

class TwitterText {

    // swiftlint:disable:next force_try
    static let linkDetector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    class func count(_ text: String, hasImage: Bool) -> Int {
        let textLength = text.characters.count // 🍣 is 1
        let objcLength = text.utf16.count // 🍣 is 2
        let objcText = text as NSString
        let objcRange = NSRange(location: 0, length: objcLength)
        let matches = linkDetector.matches(in: text, options: [], range: objcRange)

        let urlLength = matches
            .map { objcText.substring(with: $0.range) as String }
            .map { $0.characters.count }
            .reduce(0, +)

        let shortURLLength = matches.count * 23

        let imageURLLength = hasImage ? 24 : 0

        return textLength - urlLength + shortURLLength + imageURLLength
    }
}
