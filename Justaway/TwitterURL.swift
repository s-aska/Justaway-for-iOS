import Foundation
import SwiftyJSON

struct TwitterURL {
    let shortURL: String
    let displayURL: String
    let expandedURL: String

    init(_ json: JSON) {
        self.shortURL = json["url"].string ?? ""
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
    }

    init(json: [String: AnyObject]) {
        self.shortURL = json["url"] as? String ?? ""
        self.displayURL = json["display_url"] as? String ?? ""
        self.expandedURL = json["expanded_url"] as? String ?? ""
    }

    init(_ dictionary: [String: String]) {
        self.shortURL = dictionary["shortURL"] ?? ""
        self.displayURL = dictionary["displayURL"] ?? ""
        self.expandedURL = dictionary["expandedURL"] ?? ""
    }

    var dictionaryValue: [String: String] {
        return [
            "shortURL": shortURL,
            "displayURL": displayURL,
            "expandedURL": expandedURL
        ]
    }
}
