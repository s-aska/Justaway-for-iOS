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
    static let urlRegexp = try! NSRegularExpression(pattern: "https?://[^ ]+", options: NSRegularExpressionOptions.CaseInsensitive)
    static let statusUpdateURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")!
    static let mediaUploadURL = NSURL(string: "https://upload.twitter.com/1.1/media/upload.json")!

    static let session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

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

    class func updateStatusWithMedia(account: ACAccount, status: String, imageData: NSData) {
        let media = imageData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: mediaUploadURL, parameters: ["media": media])
        socialRequest.account = account
        let completion = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if let error = error {
                NSLog("\(error.localizedDescription)")
            }
            if let data = data {
                do {
                    let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    if let media_id = json["media_id_string"] as? String {
                        updateStatusWithMedia(account, status: status, mediaID: media_id)
                    }
                } catch let error as NSError {
                    NSLog("\(error.localizedDescription)")
                }
            }
        }
        session.dataTaskWithRequest(socialRequest.preparedURLRequest(), completionHandler: completion).resume()
    }

    class func updateStatus(account: ACAccount, status: String) {
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: statusUpdateURL, parameters: ["status": status])
        socialRequest.account = account
        session.dataTaskWithRequest(socialRequest.preparedURLRequest()).resume()
    }

    class func updateStatusWithMedia(account: ACAccount, status: String, mediaID: String) {
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: statusUpdateURL, parameters: ["status": status, "media_ids": mediaID])
        socialRequest.account = account
        session.dataTaskWithRequest(socialRequest.preparedURLRequest()).resume()
    }
}
