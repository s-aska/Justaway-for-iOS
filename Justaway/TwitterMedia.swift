import Foundation
import SwiftyJSON
import TwitterAPI

struct TwitterMedia {
    let shortURL: String
    let displayURL: String
    let expandedURL: String
    let mediaURL: URL
    let videoURL: String
    let height: Int
    let width: Int

    init(_ json: JSON) {
        self.shortURL = json["url"].string ?? ""
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
        self.mediaURL = URL(string: json["media_url_https"].string ?? "")!
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

    init(json: [String: AnyObject]) {
        self.shortURL = json["url"] as? String ?? ""
        self.displayURL = json["display_url"] as? String ?? ""
        self.expandedURL = json["expanded_url"] as? String ?? ""
        self.mediaURL = URL(string: json["media_url_https"] as? String ?? "")!
        let sizes = json["sizes"] as? [String: AnyObject] ?? [:]
        let large = sizes["large"] as? [String: AnyObject] ?? [:]
        self.height = large["h"] as? Int ?? 0
        self.width = large["w"] as? Int ?? 0
        self.videoURL = json["video_url"] as? String ?? ""
    }

    var mediaThumbURL: URL {
        return URL(string: mediaURL.absoluteString + ":thumb")!
    }

    init(_ dictionary: [String: AnyObject]) {
        self.shortURL = dictionary["shortURL"] as? String ?? ""
        self.displayURL = dictionary["displayURL"] as? String ?? ""
        self.expandedURL = dictionary["expandedURL"] as? String ?? ""
        self.mediaURL = URL(string: dictionary["mediaURL"] as? String ?? "")!
        self.height = dictionary["height"] as? Int ?? 0
        self.width = dictionary["width"] as? Int ?? 0
        self.videoURL = dictionary["videoURL"] as? String ?? ""
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "shortURL": shortURL as AnyObject,
            "displayURL": displayURL as AnyObject,
            "expandedURL": expandedURL as AnyObject,
            "mediaURL": mediaURL.absoluteString as AnyObject,
            "videoURL": videoURL as AnyObject,
            "height": height as AnyObject,
            "width": width as AnyObject
        ]
    }
}
