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
        let musicURL: URL
        let titleWithArtist: String
        let albumURL: URL?
    }

    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    class func isShareURL(_ string: String) -> Bool {
        return string.hasPrefix("https://play.google.com/music/")
    }

    class func encodeShareURL(_ string: NSString) -> String {
        let range = string.range(of: "=")
        if range.location != NSNotFound {
            let title = string.substring(from: range.location + 1)
            if let encodeQuery = title.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) {
                return string.substring(to: range.location + 1) + encodeQuery + "&hl=en"
            }
        }
        return string as String
    }

    class func getTitleByShareURL(_ string: NSString) -> String {
        let range = string.range(of: "=")
        if range.location != NSNotFound {
            return string.substring(from: range.location + 1)
        }
        return ""
    }

    class func loadMetaFromShareURL(_ shareURL: String, completion: @escaping ((MusicInfo) -> Void)) {
        if !isShareURL(shareURL) {
            return
        }
        guard let musicURL = URL(string: encodeShareURL(shareURL as NSString)) else {
            return
        }
        let ogpCompletion = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                return
            }
            guard let html = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                return
            }
            let ogps = OGPParser.parse(html)
            guard let titleContent = ogps.filter({ $0.type == .Title }).first?.content else {
                return
            }
            let titleWithArtist = titleContent == "Listen on Google Play Music" ? GooglePlayMusic.getTitleByShareURL(shareURL as NSString) : titleContent
            if let content = ogps.filter({ $0.type == .Image }).first?.content, var imageURLComponents = URLComponents(string: content) {
                imageURLComponents.scheme = "https"
                if let imageURL = imageURLComponents.url {
                    completion(MusicInfo(musicURL: musicURL, titleWithArtist: titleWithArtist, albumURL: imageURL))
                    return
                }
            }
            completion(MusicInfo(musicURL: musicURL, titleWithArtist: titleWithArtist, albumURL: nil))
        }
        session.dataTask(with: musicURL, completionHandler: ogpCompletion).resume()
    }
}
