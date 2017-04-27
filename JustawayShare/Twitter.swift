//
//  Twitter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/24/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import Social
import Accounts

class Twitter {

    // swiftlint:disable:next force_try
    static let urlRegexp = try! NSRegularExpression(pattern: "https?://[^ ]+", options: NSRegularExpression.Options.caseInsensitive)
    static let statusUpdateURL = URL(string: "https://api.twitter.com/1.1/statuses/update.json")!
    static let mediaUploadURL = URL(string: "https://upload.twitter.com/1.1/media/upload.json")!

    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    class func count(_ text: String, hasImage: Bool) -> Int {
        var count = text.characters.count
        let s = text as NSString
        let matches = urlRegexp.matches(in: text, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            let url = s.substring(with: match.rangeAt(0)) as String
            let urlCount = url.hasPrefix("https") ? 23 : 22
            count = count + urlCount - url.characters.count
        }
        if hasImage {
            count = count + 24
        }
        return count
    }

    class func updateStatusWithMedia(_ account: ACAccount, status: String, imageData: Data) {
        let media = imageData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: mediaUploadURL, parameters: ["media": media])
        socialRequest?.account = account
        let completion = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if let error = error {
                NSLog("\(error.localizedDescription)")
            }
            if let data = data {
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    if let media_id = json?["media_id_string"] as? String {
                        updateStatusWithMedia(account, status: status, mediaID: media_id)
                    }
                } catch let error as NSError {
                    NSLog("\(error.localizedDescription)")
                }
            }
        }
        session.dataTask(with: (socialRequest?.preparedURLRequest())!, completionHandler: completion).resume()
    }

    class func updateStatus(_ account: ACAccount, status: String) {
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: statusUpdateURL, parameters: ["status": status])
        socialRequest?.account = account
        session.dataTask(with: (socialRequest?.preparedURLRequest())!).resume()
    }

    class func updateStatusWithMedia(_ account: ACAccount, status: String, mediaID: String) {
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: statusUpdateURL, parameters: ["status": status, "media_ids": mediaID])
        socialRequest?.account = account
        session.dataTask(with: (socialRequest?.preparedURLRequest())!).resume()
    }
}
