import Foundation
import SwifteriOS

struct TwitterURL {
    let displayURL: String
    let expandedURL: String
    
    init(_ json: JSONValue) {
        self.displayURL = json["display_url"].string ?? ""
        self.expandedURL = json["expanded_url"].string ?? ""
    }
}
