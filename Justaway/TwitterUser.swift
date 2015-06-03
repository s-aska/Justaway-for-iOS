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

struct TwitterUserFull {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    let isProtected: Bool
    let createdAt: String
    let description: String
    let urls: [TwitterURL]
    let followRequestSent: Bool
    let following: Bool
    let location: String
    let profileBackgroundImageURL: NSURL
    let siteURL: NSURL
    let favouritesCount: Int
    let followersCount: Int
    let friendsCount: Int
    let listedCount: Int
    let statusesCount: Int
    
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
        if let url = json["profile_background_image_url"].string {
            self.profileBackgroundImageURL = NSURL(string: url.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))!
        } else {
            self.profileBackgroundImageURL = NSURL(string: json["profile_background_image_url"].string ?? "")!
        }
        self.createdAt = json["created_at"].string ?? ""
        self.description = json["description"].string ?? ""
        if let urls = json["entities"]["urls"].array {
            self.urls = urls.map { TwitterURL($0) }
        } else {
            self.urls = [TwitterURL]()
        }
        self.followRequestSent = json["follow_request_sent"].boolValue
        self.following = json["following"].boolValue
        self.location = json["location"].string ?? ""

        self.siteURL = NSURL(string: json["url"].string ?? "")!
        self.favouritesCount = json["favourites_count"].integer ?? 0
        self.followersCount = json["followers_count"].integer ?? 0
        self.friendsCount = json["friends_count"].integer ?? 0
        self.listedCount = json["listed_count"].integer ?? 0
        self.statusesCount = json["statuses_count"].integer ?? 0
    }
    
//    init(_ dictionary: [String: AnyObject]) {
//        self.userID = dictionary["userID"] as? String ?? ""
//        self.screenName = dictionary["screenName"] as? String ?? ""
//        self.name = dictionary["name"] as? String ?? ""
//        self.profileImageURL = NSURL(string: dictionary["profileImageURL"] as? String ?? "")!
//        self.isProtected = dictionary["isProtected"] as? Bool ?? false
//        self.createdAt = dictionary["createdAt"] as? String ?? ""
//        self.description = dictionary["description"] as? String ?? ""
//    }
//    
//    var dictionaryValue: [String: AnyObject] {
//        return [
//            "userID": userID,
//            "screenName": screenName,
//            "name": name,
//            "isProtected": isProtected,
//            "profileImageURL": profileImageURL.absoluteString ?? "",
//            "createdAt": createdAt,
//            "description": description
//        ]
//    }
}
