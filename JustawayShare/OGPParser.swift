//
//  OGPParser.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/24/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation

class OGPParser {

    // swiftlint:disable:next force_try
    static let regexpOgp = try! NSRegularExpression(pattern: "<meta property=\"og:([^\"]+)\" content=[\"']([^\"']+)[\"'] ?/?>",
                                                    options: NSRegularExpression.Options.useUnicodeWordBoundaries.intersection(NSRegularExpression.Options.dotMatchesLineSeparators))

    enum OGPType: String {
        case Title = "title", Image = "image"
    }

    struct OGP {
        let type: OGPType
        let content: String
        init?(type: String, content: String) {
            guard let type = OGPType(rawValue: type) else {
                return nil
            }
            self.type = type
            self.content = content
        }
    }

    class func parse(_ html: NSString) -> [OGP] {
        let s = html as String
        let matches = regexpOgp.matches(in: s, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: s.utf16.count))
        return matches.flatMap { (match) -> OGP? in
            let type = html.substring(with: match.rangeAt(1))
            let content = html.substring(with: match.rangeAt(2))
            return OGP(type: type, content: content)
        }
    }
}
