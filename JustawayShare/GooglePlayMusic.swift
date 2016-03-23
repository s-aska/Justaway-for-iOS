//
//  GooglePlayMusic.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/24/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation

class GooglePlayMusic {

    struct MusicInfo {
        let musicURL: NSURL
        let titleWithArtist: String
        let albumURL: NSURL?
    }

    static let session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    class func isShareURL(string: String) -> Bool {
        return string.hasPrefix("https://play.google.com/music/")
    }

    class func encodeShareURL(string: NSString) -> String {
        let range = string.rangeOfString("=")
        if range.location != NSNotFound {
            let title = string.substringFromIndex(range.location + 1)
            if let encodeQuery = title.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                return string.substringToIndex(range.location + 1) + encodeQuery + "&hl=en"
            }
        }
        return string as String
    }

    class func getTitleByShareURL(string: NSString) -> String {
        let range = string.rangeOfString("=")
        if range.location != NSNotFound {
            return string.substringFromIndex(range.location + 1)
        }
        return ""
    }

    class func loadMetaFromShareURL(shareURL: String, completion: (MusicInfo -> Void)) {
        if !isShareURL(shareURL) {
            return
        }
        guard let musicURL = NSURL(string: encodeShareURL(shareURL)) else {
            return
        }
        let ogpCompletion = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let data = data else {
                return
            }
            guard let html = NSString(data: data, encoding: NSUTF8StringEncoding) else {
                return
            }
            let ogps = OGPParser.parse(html)
            guard let titleContent = ogps.filter({ $0.type == .Title }).first?.content else {
                return
            }
            let titleWithArtist = titleContent == "Listen on Google Play Music" ? GooglePlayMusic.getTitleByShareURL(shareURL) : titleContent
            if let content = ogps.filter({ $0.type == .Image }).first?.content, let imageURLComponents = NSURLComponents(string: content) {
                imageURLComponents.scheme = "https"
                if let imageURL = imageURLComponents.URL {
                    completion(MusicInfo(musicURL: musicURL, titleWithArtist: titleWithArtist, albumURL: imageURL))
                    return
                }
            }
            completion(MusicInfo(musicURL: musicURL, titleWithArtist: titleWithArtist, albumURL: nil))
        }
        session.dataTaskWithURL(musicURL, completionHandler: ogpCompletion).resume()
    }
}
