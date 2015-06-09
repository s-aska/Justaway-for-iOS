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
    
    init(_ userFull: TwitterUserFull) {
        self.userID = userFull.userID
        self.screenName = userFull.screenName
        self.name = userFull.name
        self.profileImageURL = userFull.profileImageURL
        self.isProtected = userFull.isProtected
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
    
    var profileOriginalImageURL: NSURL? {
        return NSURL(string: profileImageURL.absoluteString!.stringByReplacingOccurrencesOfString("_bigger", withString: "", options: nil, range: nil))
    }
}

struct TwitterUserFull {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    let isProtected: Bool
    let createdAt: TwitterDate
    let description: String
    let urls: [TwitterURL]
    let followRequestSent: Bool
    let following: Bool
    let location: String
    let profileBannerURL: NSURL
    let displayURL: String
    let expandedURL: NSURL?
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
        if let url = json["profile_banner_url"].string {
            self.profileBannerURL = NSURL(string: url + "/mobile_retina")!
        } else {
            self.profileBannerURL = NSURL(string: json["profile_background_image_url"].string ?? "")!
        }
        self.createdAt = TwitterDate(json["created_at"].string ?? "")
        self.description = json["description"].string ?? ""
        if let urls = json["entities"]["url"]["urls"].array {
            self.urls = urls.map { TwitterURL($0) }
        } else {
            self.urls = [TwitterURL]()
        }
        self.followRequestSent = json["follow_request_sent"].boolValue
        self.following = json["following"].boolValue
        self.location = json["location"].string ?? ""

        var displayURL = json["url"].string ?? ""
        var expandedURL: NSURL?
        self.favouritesCount = json["favourites_count"].integer ?? 0
        self.followersCount = json["followers_count"].integer ?? 0
        self.friendsCount = json["friends_count"].integer ?? 0
        self.listedCount = json["listed_count"].integer ?? 0
        self.statusesCount = json["statuses_count"].integer ?? 0
        
        for url in self.urls {
            if url.shortURL == displayURL {
                displayURL = url.displayURL
                expandedURL = NSURL(string: url.expandedURL)
                break
            }
        }
        self.expandedURL = expandedURL
        self.displayURL = displayURL
    }
}
