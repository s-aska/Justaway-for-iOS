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
        self.mediaURL = NSURL(string: json["media_url"].string ?? "")!
        self.height = json["sizes"]["large"]["h"].integer ?? 0
        self.width = json["sizes"]["large"]["w"].integer ?? 0
    }
    
    var mediaThumbURL: NSURL {
        return NSURL(string: self.mediaURL.absoluteString! + ":thumb")!
    }
}
