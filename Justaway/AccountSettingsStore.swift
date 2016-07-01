import Foundation
import KeyClip
import TwitterAPI
import Accounts
import EventBox

class AccountSettingsCache {
    struct Static {
        static let instance: AccountSettingsCache = AccountSettingsCache()
    }
    class var sharedInstance: AccountSettingsCache {
        return Static.instance
    }
    private var settings: AccountSettings?
}

class AccountSettingsStore {

    // MARK: - Types

    struct Constants {
        static let keychainKey = "AccountService/v2"
    }

    class func get() -> AccountSettings? {
        return AccountSettingsCache.sharedInstance.settings
    }

    class func setup() {
        if let settings = AccountSettingsCache.sharedInstance.settings {
            if settings.hasAccountClient() {
                reloadACAccounts(settings)
            }
        } else {
            load()
        }
    }

    // MARK: - Public Methods

    class func save(settings: AccountSettings) -> Bool {
        assert(settings.accounts.count > 0, "settings.accounts.count is zero")
        assert(settings.accounts.count > settings.current, "current out of range")

        AccountSettingsCache.sharedInstance.settings = settings

        return KeyClip.save(Constants.keychainKey, dictionary: settings.dictionaryValue)
    }

    class func load() {
        if let data: NSDictionary = KeyClip.load(Constants.keychainKey), settings = AccountSettings(data) {
            if settings.hasAccountClient() {
                reloadACAccounts(settings)
            } else {
                AccountSettingsCache.sharedInstance.settings = settings
                EventBox.post(twitterAuthorizeNotification)
            }
        } else {
            Twitter.addACAccount(true)
        }
    }

    class func reloadACAccounts(settings: AccountSettings) {
        var activeAccounts = [Account]()
        let callback = { (acAccounts: [ACAccount]) in
            NSLog("refreshACAccounts retrieve count:\(acAccounts.count)")
            var acAccountMap = [String: ACAccount]()
            for acAccount in acAccounts {
                acAccountMap[acAccount.valueForKeyPath("properties.user_id") as? String ?? ""] = acAccount
            }
            for account in settings.accounts {
                switch account.client {
                case let client as AccountClient:
                    if let acAccount = acAccountMap.removeValueForKey(account.userID) {
                        NSLog("refreshACAccounts update \(account.userID) \(client.identifier) => \(acAccount.identifier!)")
                        activeAccounts.append(Account(account: account, acAccount: acAccount))
                    } else {
                        NSLog("refreshACAccounts delete \(account.userID) \(client.identifier)")
                    }
                case _ as OAuthClient:
                    activeAccounts.append(account)
                default:
                    activeAccounts.append(account)
                }
            }
            if activeAccounts.count > 0 {
                NSLog("refreshACAccounts update complete")
                let current = min(settings.current, activeAccounts.count)
                AccountSettingsCache.sharedInstance.settings = AccountSettings(current: current, accounts: activeAccounts)
            } else {
                NSLog("refreshACAccounts all deleted")
                AccountSettingsStore.clear()
            }
            EventBox.post(twitterAuthorizeNotification)
        }
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in

            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                callback(twitterAccounts)
            } else {
                callback([])
            }
        }
    }

    class func clear() {
        AccountSettingsCache.sharedInstance.settings = nil

        KeyClip.delete(Constants.keychainKey)
    }

    class func isCurrent(userID: String) -> Bool {
        if let account = get()?.account() {
            return account.userID == userID
        }
        return false
    }

}
