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
        if let settings = AccountSettingsCache.sharedInstance.settings {
            return settings
        } else {
            return load()
        }
    }
    
    // MARK: - Public Methods
    
    class func save(settings: AccountSettings) -> Bool {
        assert(settings.accounts.count > 0, "settings.accounts.count is zero")
        assert(settings.accounts.count > settings.current, "current out of range")
        
        AccountSettingsCache.sharedInstance.settings = settings
        
        return KeyClip.save(Constants.keychainKey, dictionary: settings.dictionaryValue)
    }
    
    class func load() -> AccountSettings? {
        if let data: NSDictionary = KeyClip.load(Constants.keychainKey) {
            let settings = AccountSettings(data)
            AccountSettingsCache.sharedInstance.settings = settings
            for account in settings.accounts {
                if let _ = account.client as? AccountClient {
                    refreshACAccounts(settings)
                    NSLog("found ACAccount")
                    break
                }
            }
        } else {
            return nil
        }
        
        return AccountSettingsCache.sharedInstance.settings
    }
    
    class func refreshACAccounts(settings: AccountSettings) {
        var activeAccounts = [Account]()
        let callback = { (acAccounts: [ACAccount]) in
            NSLog("new ACAccounts count:\(acAccounts.count)")
            var updated = false
            var acAccountMap = [String: ACAccount]()
            for acAccount in acAccounts {
                acAccountMap[acAccount.identifier!] = acAccount
            }
            for account in settings.accounts {
                switch account.client {
                case let client as AccountClient:
                    if let _ = acAccountMap.removeValueForKey(client.identifier) {
                        NSLog("exists \(client.identifier)")
                        activeAccounts.append(account)
                    } else {
                        NSLog("missing \(client.identifier)")
                        updated = true
                    }
                case _ as OAuthClient:
                    activeAccounts.append(account)
                default:
                    activeAccounts.append(account)
                }
            }
            if acAccountMap.values.count > 0 {
                for account in acAccountMap.values {
                    NSLog("new account count:\(acAccountMap.values.count)")
                    activeAccounts.append(
                        Account(
                            client: AccountClient(account: account),
                            userID: account.valueForKeyPath("properties.user_id") as! String,
                            screenName: account.username,
                            name: account.username,
                            profileImageURL: NSURL(string: "")!,
                            profileBannerURL: NSURL(string: "")!))
                }
                Twitter.refreshAccounts(activeAccounts)
            } else if updated {
                NSLog("new account no")
                if activeAccounts.count > 0 {
                    let current = min(settings.current, activeAccounts.count)
                    AccountSettingsCache.sharedInstance.settings = AccountSettings(current: current, accounts: activeAccounts)
                } else {
                    AccountSettingsStore.clear()
                }
                EventBox.post(TwitterAuthorizeNotification)
            }
        }
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
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
