import Foundation
import SwiftyJSON
import TwitterAPI

struct TwitterMedia {
    let shortURL: String
    let displayURL: String
    let expandedURL: String
    let mediaURL: NSURL
    let videoURL: String
    let height: Int
    let width: Int
    let auth: Bool

    init(_ json: JSON, auth: Bool = false) {
        self.auth = auth
        self.shortURL = json["url"].string ?? ""
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
        self.mediaURL = NSURL(string: json["media_url_https"].string ?? "")!
        self.height = json["sizes"]["large"]["h"].int ?? 0
        self.width = json["sizes"]["large"]["w"].int ?? 0
        self.videoURL = {
            if let variants = json["video_info"]["variants"].array {
                for variant in variants {
                    if let url = variant["url"].string {
                        if url.hasSuffix("mp4") {
                            return url
                        }
                    }
                }
            }
            return ""
        }()
    }

    init(json: [String: AnyObject], auth: Bool = false) {
        self.auth = auth
        self.shortURL = json["url"] as? String ?? ""
        self.displayURL = json["display_url"] as? String ?? ""
        self.expandedURL = json["expanded_url"] as? String ?? ""
        self.mediaURL = NSURL(string: json["media_url_https"] as? String ?? "")!
        let sizes = json["sizes"] as? [String: AnyObject] ?? [:]
        let large = sizes["large"] as? [String: AnyObject] ?? [:]
        self.height = large["h"] as? Int ?? 0
        self.width = large["w"] as? Int ?? 0
        self.videoURL = json["video_url"] as? String ?? ""
    }

    var mediaThumbURL: NSURL {
        if auth {
            return Twitter.authorizationURL(NSURL(string: mediaURL.absoluteString + ":thumb")!) ?? NSURL()
        }
        return NSURL(string: mediaURL.absoluteString + ":thumb")!
    }

    var mediaOriginalURL: NSURL {
        if auth {
            return Twitter.authorizationURL(mediaURL) ?? NSURL()
        }
        return mediaURL
    }

    init(_ dictionary: [String: AnyObject], auth: Bool = false) {
        self.auth = auth
        self.shortURL = dictionary["shortURL"] as? String ?? ""
        self.displayURL = dictionary["displayURL"] as? String ?? ""
        self.expandedURL = dictionary["expandedURL"] as? String ?? ""
        self.mediaURL = NSURL(string: dictionary["mediaURL"] as? String ?? "")!
        self.height = dictionary["height"] as? Int ?? 0
        self.width = dictionary["width"] as? Int ?? 0
        self.videoURL = dictionary["videoURL"] as? String ?? ""
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "shortURL": shortURL,
            "displayURL": displayURL,
            "expandedURL": expandedURL,
            "mediaURL": mediaURL.absoluteString,
            "videoURL": videoURL,
            "height": height,
            "width": width
        ]
    }
}
