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
        static let tabs = "tabs"
    }

    let client: Client
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    let profileBannerURL: NSURL
    let tabs: [Tab]

    init(client: Client, userID: String, screenName: String, name: String, profileImageURL: NSURL, profileBannerURL: NSURL) {
        self.client = client
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
        self.profileBannerURL = profileBannerURL
        self.tabs = [
            Tab(type: .HomeTimline, userID: userID, arguments: [:]),
            Tab(type: .Notifications, userID: userID, arguments: [:]),
            Tab(type: .Favorites, userID: userID, arguments: [:])
        ]
    }

    init(_ dictionary: NSDictionary) {
        self.userID = dictionary[Constants.userID] as? String ?? "-"
        self.screenName = dictionary[Constants.screenName] as? String ?? "-"
        self.name = dictionary[Constants.name] as? String ?? "-"
        if let profileImageURL = dictionary[Constants.profileImageURL] as? String {
            self.profileImageURL = NSURL(string: profileImageURL) ?? NSURL()
        } else {
            self.profileImageURL = NSURL()
        }
        if let profileBannerURL = dictionary[Constants.profileBannerURL] as? String {
            self.profileBannerURL = NSURL(string: profileBannerURL) ?? NSURL()
        } else {
            self.profileBannerURL = NSURL()
        }
        if let tabs = dictionary[Constants.tabs] as? [NSDictionary] {
            self.tabs = tabs.map({ Tab($0) })
        } else {
            self.tabs = [
                Tab(type: .HomeTimline, userID: userID, arguments: [:]),
                Tab(type: .Notifications, userID: userID, arguments: [:]),
                Tab(type: .Favorites, userID: userID, arguments: [:])
            ]
        }

        if let serializedString = dictionary[Constants.client] as? String {
            self.client = ClientDeserializer.deserialize(serializedString)
        } else {
            fatalError("missing client serializedString")
        }
    }

    init(account: Account, user: TwitterUserFull) {
        self.client = account.client
        self.userID = user.userID
        self.screenName = user.screenName
        self.name = user.name
        self.profileImageURL = user.profileImageURL
        self.profileBannerURL = user.profileBannerURL
        self.tabs = account.tabs
    }

    init(account: Account, acAccount: ACAccount) {
        self.client = AccountClient(account: acAccount)
        self.userID = account.userID
        self.screenName = account.screenName
        self.name = account.name
        self.profileImageURL = account.profileImageURL
        self.profileBannerURL = account.profileBannerURL
        self.tabs = account.tabs
    }

    init(account: Account, tabs: [Tab]) {
        self.client = account.client
        self.userID = account.userID
        self.screenName = account.screenName
        self.name = account.name
        self.profileImageURL = account.profileImageURL
        self.profileBannerURL = account.profileBannerURL
        self.tabs = tabs.count > 0 ? tabs : [
            Tab(type: .HomeTimline, userID: userID, arguments: [:]),
            Tab(type: .Notifications, userID: userID, arguments: [:]),
            Tab(type: .Favorites, userID: userID, arguments: [:])
        ]
    }

    var profileImageBiggerURL: NSURL {
        return NSURL(string: profileImageURL.absoluteString.stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: [], range: nil))!
    }

    var dictionaryValue: NSDictionary {
        return [
            Constants.client           : client.serialize,
            Constants.userID           : userID,
            Constants.screenName       : screenName,
            Constants.name             : name,
            Constants.profileImageURL  : profileImageURL.absoluteString,
            Constants.profileBannerURL : profileBannerURL.absoluteString,
            Constants.tabs             : tabs.map({ $0.dictionaryValue })
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
        self.current = dictionary[Constants.current] as? Int ?? 0
        self.accounts = (dictionary[Constants.accounts] as? [NSDictionary] ?? []).map({ Account($0) })
    }

    // MARK: - Public Methods

    func account() -> Account {
        return accounts[current]
    }

    func account(index: Int) -> Account {
        return accounts[index]
    }

    func merge(newAccounts: [Account]) -> AccountSettings {
        var newAccountDictionary = [String: Account]()
        for newAccount in newAccounts {
            newAccountDictionary[newAccount.userID] = newAccount
        }

        // keep sequence
        var mergeAccounts = accounts.map({ newAccountDictionary.removeValueForKey($0.userID) ?? $0 })
        for newAccount in newAccountDictionary.values {
            mergeAccounts.insert(newAccount, atIndex: 0)
        }

        let currentUserID = account().userID
        let current = mergeAccounts.indexOf { $0.userID == currentUserID } ?? 0
        return AccountSettings(current: current, accounts: mergeAccounts)
    }

    func update(users: [TwitterUserFull]) -> AccountSettings {
        let updateAccounts = accounts.map { (account: Account) -> Account in
            if let user = users.filter({ $0.userID == account.userID }).first {
                return Account(account: account, user: user)
            } else {
                return account
            }
        }
        return AccountSettings(current: current, accounts: updateAccounts)
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
