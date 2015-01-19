import Foundation
import SwifteriOS

struct TwitterUser {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    let isProtected: Bool
    
    init(_ json: JSONValue) {
        self.userID = json["id_str"].string ?? ""
        self.screenName = json["screen_name"].string ?? ""
        self.name = json["name"].string ?? ""
        self.isProtected = json["protected"].boolValue ? true : false
        if let url = json["profile_image_url"].string {
            self.profileImageURL = NSURL(string: url.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))!
        } else {
            self.profileImageURL = NSURL(string: json["profile_image_url"].string ?? "")!
        }
    }
    
    init(_ dictionary: [String: AnyObject]) {
        self.userID = dictionary["userID"] as? String ?? ""
        self.screenName = dictionary["screenName"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.profileImageURL = NSURL(string: dictionary["profileImageURL"] as? String ?? "")!
        self.isProtected = dictionary["isProtected"] as? Bool ?? false
    }
    
    var dictionaryValue: [String: AnyObject] {
        return [
            "userID": userID,
            "screenName": screenName,
            "name": name,
            "isProtected": isProtected,
            "profileImageURL": profileImageURL.absoluteString ?? ""
        ]
    }
}
