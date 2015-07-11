import Foundation
import SwifteriOS

struct TwitterMedia {
    let displayURL: String
    let expandedURL: String
    let mediaURL: NSURL
    let height: Int
    let width: Int
    
    init(_ json: JSONValue) {
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
        self.mediaURL = NSURL(string: json["media_url_https"].string ?? "")!
        self.height = json["sizes"]["large"]["h"].integer ?? 0
        self.width = json["sizes"]["large"]["w"].integer ?? 0
    }
    
    var mediaThumbURL: NSURL {
        return NSURL(string: self.mediaURL.absoluteString + ":thumb")!
    }
    
    init(_ dictionary: [String: AnyObject]) {
        self.displayURL = dictionary["displayURL"] as? String ?? ""
        self.expandedURL = dictionary["expandedURL"] as? String ?? ""
        self.mediaURL = NSURL(string: dictionary["mediaURL"] as? String ?? "")!
        self.height = dictionary["height"] as? Int ?? 0
        self.width = dictionary["width"] as? Int ?? 0
    }
    
    var dictionaryValue: [String: AnyObject] {
        return [
            "displayURL": displayURL,
            "expandedURL": expandedURL,
            "mediaURL": mediaURL.absoluteString ?? "",
            "height": height,
            "width": width
        ]
    }
}
