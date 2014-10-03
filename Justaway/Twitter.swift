import Foundation
import SwifteriOS

let failureHandler = { (error: NSError) -> Void in
    NSLog("%@", error.localizedDescription)
}

class TwitterUser {
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    init(_ dictionary: Dictionary<String, JSONValue>) {
        self.userID = dictionary["id_str"]?.string ?? ""
        self.screenName = dictionary["screen_name"]?.string ?? ""
        self.name = dictionary["name"]?.string ?? ""
        self.profileImageURL = NSURL(string: dictionary["profile_image_url"]?.string ?? "")
    }
}

class Twitter {
    class func refreshAccounts(newAccounts: Array<AccountSettings.Account>, successHandler: (Array<AccountSettings.Account> -> Void)) {
        var accounts = Array<AccountSettings.Account>()
        var current = 0
        let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        if let accountSettings = AccountSettingsStore.get() {
            let currentUserID = accountSettings.account().userID
            var newAccountMap = Dictionary<String, AccountSettings.Account>()
            for newAccount in newAccounts {
                newAccountMap[newAccount.userID] = newAccount
            }
            accounts = accountSettings.accounts
            accounts = accounts.map({ account in
                newAccountMap.removeValueForKey(account.userID) ?? account
            })
            for newAccount in newAccountMap.values {
                accounts.insert(newAccount, atIndex: 0)
            }
            for i in 0 ... accounts.count {
                if accounts[i].userID == currentUserID {
                    current = i
                    break
                }
            }
            swifter.client.credential = accountSettings.account().credential
        } else if newAccounts.count > 0 {
            accounts = newAccounts
            swifter.client.credential = accounts[0].credential
        } else {
            return
        }
        let userIDs: Array<Int> = accounts.map({ accounts in accounts.userID.toInt()! })
        swifter.getUsersLookupWithUserIDs(userIDs, includeEntities: false, success: { rows in
            var userMap = Dictionary<String, TwitterUser>()
            for row in rows! {
                let user = TwitterUser(row.object!)
                userMap[user.userID] = user
            }
            accounts = accounts.map({ account in
                if let user = userMap[account.userID] {
                    return AccountSettings.Account(
                        credential: account.credential,
                        userID: user.userID,
                        screenName: user.screenName,
                        name: user.name,
                        profileImageURL: user.profileImageURL)
                } else {
                    return account
                }
            })
            NSLog("refreshAccounts current:%i", current)
            AccountSettingsStore.save(AccountSettings(current: current, accounts: accounts))
            successHandler(accounts)
            }, failure: failureHandler)
    }
}
