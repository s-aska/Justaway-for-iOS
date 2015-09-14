import Foundation
import Accounts

class Account {
    
    struct Constants {
        static let identifier = "identifier"
        static let key = "key"
        static let secret = "secret"
        static let userID = "user_id"
        static let screenName = "screen_name"
        static let name = "name"
        static let profileImageURL = "profile_image_url_https"
    }
    
    let client: TwitterAPIClient
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    init(client: TwitterAPIClient, userID: String, screenName: String, name: String, profileImageURL: NSURL) {
        self.client = client
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
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
        if dictionary[Constants.identifier] != nil {
            let account = ACAccountStore().accountWithIdentifier(dictionary[Constants.identifier])
            self.client = TwitterAPI.client(account: account)
        } else {
            self.client = TwitterAPI.client(
                consumerKey: TwitterConsumerKey,
                consumerSecret: TwitterConsumerSecret,
                accessToken: dictionary[Constants.key]!,
                accessTokenSecret: dictionary[Constants.secret]!)
        }
    }
    
    var profileImageBiggerURL: NSURL {
        return NSURL(string: profileImageURL.absoluteString.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: [], range: nil))!
    }
    
    var dictionaryValue: [String: String] {
        switch client.credential {
        case .Account(let account):
            return [
                Constants.identifier      : account.identifier!,
                Constants.userID          : self.userID,
                Constants.screenName      : self.screenName,
                Constants.name            : self.name,
                Constants.profileImageURL : self.profileImageURL.absoluteString
            ]
        case .OAuth(let credential):
            return [
                Constants.key             : credential.oauth_token,
                Constants.secret          : credential.oauth_token_secret,
                Constants.userID          : self.userID,
                Constants.screenName      : self.screenName,
                Constants.name            : self.name,
                Constants.profileImageURL : self.profileImageURL.absoluteString
            ]
        }
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
    
    var dictionaryValue: NSDictionary {
        return [
            Constants.current  : current,
            Constants.accounts : accounts.map({ $0.dictionaryValue })
        ]
    }
    
}
