import Foundation
import SwiftyJSON

struct TwitterUser {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: URL?
    let isProtected: Bool

    init(_ json: JSON) {
        self.userID = json["id_str"].string ?? ""
        self.screenName = json["screen_name"].string ?? ""
        self.name = json["name"].string ?? ""
        self.isProtected = json["protected"].boolValue ? true : false
        if let url = json["profile_image_url_https"].string {
            self.profileImageURL = URL(string: url.replacingOccurrences(of: "_normal", with: "_bigger", options: [], range: nil))!
        } else {
            self.profileImageURL = URL(string: json["profile_image_url_https"].string ?? "")!
        }
    }

    init(json: [String: AnyObject]) {
        self.userID = json["id_str"] as? String ?? ""
        self.screenName = json["screen_name"] as? String ?? ""
        self.name = json["name"] as? String ?? ""
        self.isProtected = json["protected"] as? Bool ?? false
        if let url = json["profile_image_url_https"] as? String {
            self.profileImageURL = URL(string: url.replacingOccurrences(of: "_normal", with: "_bigger", options: [], range: nil))!
        } else {
            self.profileImageURL = URL(string: json["profile_image_url_https"] as? String ?? "")!
        }
    }

    init(_ userFull: TwitterUserFull) {
        self.userID = userFull.userID
        self.screenName = userFull.screenName
        self.name = userFull.name
        self.profileImageURL = userFull.profileImageURL
        self.isProtected = userFull.isProtected
    }

    init(_ account: Account) {
        self.userID = account.userID
        self.screenName = account.screenName
        self.name = account.name
        self.profileImageURL = account.profileImageURL
        self.isProtected = false
    }

    init(_ dictionary: [String: AnyObject]) {
        self.userID = dictionary["userID"] as? String ?? ""
        self.screenName = dictionary["screenName"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        if let url = dictionary["profileImageURL"] as? String {
            self.profileImageURL = URL(string: url)
        } else {
            self.profileImageURL = nil
        }
        self.isProtected = dictionary["isProtected"] as? Bool ?? false
    }

    var dictionaryValue: [String: AnyObject] {
        return [
            "userID": userID as AnyObject,
            "screenName": screenName as AnyObject,
            "name": name as AnyObject,
            "isProtected": isProtected as AnyObject,
            "profileImageURL": (profileImageURL?.absoluteString ?? "") as AnyObject
        ]
    }

    var profileOriginalImageURL: URL? {
        if let url = profileImageURL {
            return URL(string: url.absoluteString.replacingOccurrences(of: "_bigger", with: "", options: [], range: nil))
        } else {
            return nil
        }
    }
}

struct TwitterUserFull {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: URL
    let isProtected: Bool
    let createdAt: TwitterDate
    let description: String
    let urls: [TwitterURL]
    let followRequestSent: Bool
    let following: Bool
    let location: String
    let profileBannerURL: URL
    let displayURL: String
    let expandedURL: URL?
    let favouritesCount: Int
    let followersCount: Int
    let friendsCount: Int
    let listedCount: Int
    let statusesCount: Int

    init(_ json: JSON) {
        self.userID = json["id_str"].string ?? ""
        self.screenName = json["screen_name"].string ?? ""
        self.name = json["name"].string ?? ""
        self.isProtected = json["protected"].boolValue ? true : false
        if let url = json["profile_image_url_https"].string {
            self.profileImageURL = URL(string: url.replacingOccurrences(of: "_normal", with: "_bigger", options: [], range: nil))!
        } else {
            self.profileImageURL = URL(string: json["profile_image_url_https"].string ?? "")!
        }
        if let url = json["profile_banner_url"].string {
            self.profileBannerURL = URL(string: url + "/mobile_retina")!
        } else {
            self.profileBannerURL = URL(string: json["profile_background_image_url_https"].string ?? "")!
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
        var expandedURL: URL?
        self.favouritesCount = json["favourites_count"].int ?? 0
        self.followersCount = json["followers_count"].int ?? 0
        self.friendsCount = json["friends_count"].int ?? 0
        self.listedCount = json["listed_count"].int ?? 0
        self.statusesCount = json["statuses_count"].int ?? 0

        for url in self.urls {
            if url.shortURL == displayURL {
                displayURL = url.displayURL
                expandedURL = URL(string: url.expandedURL)
                break
            }
        }
        self.expandedURL = expandedURL
        self.displayURL = displayURL
    }
}
