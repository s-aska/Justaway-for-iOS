import Foundation
import SwifteriOS

struct TwitterURL {
    let displayURL: String
    let expandedURL: String
    
    init(_ json: JSONValue) {
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
    }
    
    init(_ dictionary: [String: String]) {
        self.displayURL = dictionary["displayURL"] ?? ""
        self.expandedURL = dictionary["expandedURL"] ?? ""
    }
    
    var dictionaryValue: [String: String] {
        return [
            "displayURL": displayURL,
            "expandedURL": expandedURL
        ]
    }
}
