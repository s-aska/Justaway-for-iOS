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
        static let exToken = "ex_token"
    }

    let client: Client
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: URL?
    let profileBannerURL: URL?
    let tabs: [Tab]
    let exToken: String

    // swiftlint:disable function_parameter_count
    init(client: Client, userID: String, screenName: String, name: String, profileImageURL: URL?, profileBannerURL: URL?, exToken: String) {
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
        self.exToken = exToken
    }

    init(_ dictionary: NSDictionary) {
        self.userID = dictionary[Constants.userID] as? String ?? "-"
        self.screenName = dictionary[Constants.screenName] as? String ?? "-"
        self.name = dictionary[Constants.name] as? String ?? "-"
        self.exToken = dictionary[Constants.exToken] as? String ?? ""
        if let profileImageURL = dictionary[Constants.profileImageURL] as? String {
            self.profileImageURL = URL(string: profileImageURL)
        } else {
            self.profileImageURL = nil
        }
        if let profileBannerURL = dictionary[Constants.profileBannerURL] as? String {
            self.profileBannerURL = URL(string: profileBannerURL)
        } else {
            self.profileBannerURL = nil
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
        self.exToken = account.exToken
    }

    init(account: Account, acAccount: ACAccount) {
        self.client = AccountClient(account: acAccount)
        self.userID = account.userID
        self.screenName = account.screenName
        self.name = account.name
        self.profileImageURL = account.profileImageURL
        self.profileBannerURL = account.profileBannerURL
        self.tabs = account.tabs
        self.exToken = account.exToken
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
            Tab(type: .Mentions, userID: userID, arguments: [:]),
            Tab(type: .Favorites, userID: userID, arguments: [:])
        ]
        self.exToken = account.exToken
    }

    init(account: Account, exToken: String) {
        self.client = account.client
        self.userID = account.userID
        self.screenName = account.screenName
        self.name = account.name
        self.profileImageURL = account.profileImageURL
        self.profileBannerURL = account.profileBannerURL
        self.tabs = account.tabs
        self.exToken = exToken
    }

    var profileImageBiggerURL: URL? {
        if let string = profileImageURL?.absoluteString {
            return URL(string: string.replacingOccurrences(of: "_normal", with: "_bigger", options: [], range: nil))
        } else {
            return nil
        }
    }

    var isOAuth: Bool {
        return (client as? OAuthClient) != nil
    }

    var dictionaryValue: NSDictionary {
        return [
            Constants.client           : client.serialize,
            Constants.userID           : userID,
            Constants.screenName       : screenName,
            Constants.name             : name,
            Constants.profileImageURL  : profileImageURL?.absoluteString ?? "",
            Constants.profileBannerURL : profileBannerURL?.absoluteString ?? "",
            Constants.tabs             : tabs.map({ $0.dictionaryValue }),
            Constants.exToken          : exToken
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

    init?(_ dictionary: NSDictionary) {
        let current = dictionary[Constants.current] as? Int ?? 0
        let accounts = (dictionary[Constants.accounts] as? [NSDictionary] ?? []).map({ Account($0) })
        if accounts.count > 0 {
            self.current = current
            self.accounts = accounts
        } else {
            return nil
        }
    }

    // MARK: - Public Methods

    func account() -> Account? {
        return accounts.count > current ? accounts[current] : nil
    }

    func account(_ index: Int) -> Account? {
        return accounts.count > index ? accounts[index] : nil
    }

    func merge(_ newAccounts: [Account]) -> AccountSettings {
        var newAccountDictionary = [String: Account]()
        for newAccount in newAccounts {
            newAccountDictionary[newAccount.userID] = newAccount
        }

        // keep sequence
        var mergeAccounts = accounts.map({ newAccountDictionary.removeValue(forKey: $0.userID) ?? $0 })
        for newAccount in newAccountDictionary.values {
            mergeAccounts.insert(newAccount, at: 0)
        }

        let currentUserID = account()?.userID ?? ""
        let current = mergeAccounts.index { $0.userID == currentUserID } ?? 0
        return AccountSettings(current: current, accounts: mergeAccounts)
    }

    func update(_ users: [TwitterUserFull]) -> AccountSettings {
        let updateAccounts = accounts.map { (account: Account) -> Account in
            if let user = users.filter({ $0.userID == account.userID }).first {
                return Account(account: account, user: user)
            } else {
                return account
            }
        }
        return AccountSettings(current: current, accounts: updateAccounts)
    }

    func find(_ userID: String) -> Account? {
        for i in 0 ..< accounts.count {
            if accounts[i].userID == userID {
                return accounts[i]
            }
        }
        return nil
    }

    func isMe(_ userID: String) -> Bool {
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
