import Foundation
import Accounts
import TwitterAPI

class Account {
    
    struct Constants {
        static let client = "client"
        static let userID = "user_id"
        static let screenName = "screen_name"
        static let name = "name"
        static let profileImageURL = "profile_image_url_https"
        static let profileBannerURL = "profile_banner_url"
    }
    
    let client: Client
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    let profileBannerURL: NSURL
    
    init(client: Client, userID: String, screenName: String, name: String, profileImageURL: NSURL, profileBannerURL: NSURL) {
        self.client = client
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
        self.profileBannerURL = profileBannerURL
    }
    
    init(_ dictionary: [String: String]) {
        self.userID = dictionary[Constants.userID] ?? "-"
        self.screenName = dictionary[Constants.screenName] ?? "-"
        self.name = dictionary[Constants.name] ?? "-"
        if let profileImageURL = dictionary[Constants.profileImageURL] {
            self.profileImageURL = NSURL(string: profileImageURL) ?? NSURL()
        } else {
            self.profileImageURL = NSURL()
        }
        if let profileBannerURL = dictionary[Constants.profileBannerURL] {
            self.profileBannerURL = NSURL(string: profileBannerURL) ?? NSURL()
        } else {
            self.profileBannerURL = NSURL()
        }
        
        if let serializedString = dictionary[Constants.client] {
            self.client = ClientDeserializer.deserialize(serializedString)
        } else {
            fatalError("missing client serializedString")
        }
    }
    
    var profileImageBiggerURL: NSURL {
        return NSURL(string: profileImageURL.absoluteString.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: [], range: nil))!
    }
    
    var dictionaryValue: [String: String] {
        return [
            Constants.client           : client.serialize,
            Constants.userID           : userID,
            Constants.screenName       : screenName,
            Constants.name             : name,
            Constants.profileImageURL  : profileImageURL.absoluteString,
            Constants.profileBannerURL : profileBannerURL.absoluteString
        ]
    }
}

class AccountSettings {
    
    // MARK: - Types
    
    struct Constants {
        static let accounts = "accounts"
        static let current = "current"
    }
    
    // MARK: - Properties
    
    let accounts: [Account]
    let current: Int
    
    // MARK: - Initializers
    
    init(current: Int, accounts: [Account]) {
        self.current = current
        self.accounts = accounts
    }
    
    init(_ dictionary: NSDictionary) {
        self.current = dictionary[Constants.current] as! Int
        self.accounts = (dictionary[Constants.accounts] as! [Dictionary]).map({ Account($0) })
    }
    
    // MARK: - Public Methods
    
    func account() -> Account {
        return accounts[current]
    }
    
    func account(index: Int) -> Account {
        return accounts[index]
    }
    
    func find(userID: String) -> Account? {
        for i in 0 ..< accounts.count {
            if accounts[i].userID == userID {
                return accounts[i]
            }
        }
        return nil
    }
    
    func isMe(userID: String) -> Bool {
        return find(userID) == nil ? false : true
    }
    
    func hasAccountClient() -> Bool {
        for account in accounts {
            if let _ = account.client as? AccountClient {
                return true
            }
        }
        return false
    }
    
    var dictionaryValue: NSDictionary {
        return [
            Constants.current  : current,
            Constants.accounts : accounts.map({ $0.dictionaryValue })
        ]
    }
    
}
