import Foundation
import Accounts
import SwifteriOS

class Account {
    
    struct Constants {
        static let identifier = "identifier"
        static let key = "key"
        static let secret = "secret"
        static let userID = "user_id"
        static let screenName = "screen_name"
        static let name = "name"
        static let profileImageURL = "profile_image_url"
    }
    
    let credential: SwifterCredential
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    init(credential: SwifterCredential, userID: String, screenName: String, name: String, profileImageURL: NSURL) {
        self.credential = credential
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
    }
    
    init(_ dictionary: [String: String]) {
        self.userID = dictionary[Constants.userID]!
        self.screenName = dictionary[Constants.screenName]!
        self.name = dictionary[Constants.name]!
        self.profileImageURL = NSURL(string: dictionary[Constants.profileImageURL]!)!
        if dictionary[Constants.identifier] != nil {
            let account = ACAccountStore().accountWithIdentifier(dictionary[Constants.identifier])
            self.credential = SwifterCredential(account: account)
        } else {
            let accessToken = SwifterCredential.OAuthAccessToken(key: dictionary[Constants.key]!, secret: dictionary[Constants.secret]!)
            self.credential = SwifterCredential(accessToken: accessToken)
        }
    }
    
    var profileImageBiggerURL: NSURL {
        return NSURL(string: profileImageURL.absoluteString.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: [], range: nil))!
    }
    
    var dictionaryValue: [String: String] {
        if let account = credential.account {
            return [
                Constants.identifier      : account.identifier!,
                Constants.userID          : self.userID,
                Constants.screenName      : self.screenName,
                Constants.name            : self.name,
                Constants.profileImageURL : self.profileImageURL.absoluteString
            ]
        } else if let accessToken = credential.accessToken {
            return [
                Constants.key             : accessToken.key,
                Constants.secret          : accessToken.secret,
                Constants.userID          : self.userID,
                Constants.screenName      : self.screenName,
                Constants.name            : self.name,
                Constants.profileImageURL : self.profileImageURL.absoluteString
            ]
        } else {
            fatalError("Invalid credential.")
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
