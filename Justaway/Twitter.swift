import Foundation
import SwifteriOS

let TwitterAuthorizeNotification = "TwitterAuthorizeNotification"

class Twitter {
    
    // MARK: - Singleton
    
    struct Static {
        static let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
    }
    
    class var swifter : Swifter { return Static.swifter }
    
    // MARK: - Class Methods
    
    class func getClient(account: Account) -> Swifter {
        if let ac = account.credential.account {
            return Swifter(account: ac)
        } else {
            swifter.client.credential = account.credential
            return swifter
        }
    }
    
    class func addOAuthAccount() {
        let failure: ((NSError) -> Void) = {
            error in
            
            if error.code == 401 {
                NSLog("%@", "[FATAL] Please set a Your Twitter Consumer Key and Secret for the Secret.swift")
            } else if error.code == -1009 {
                NSLog("%@", "[FATAL] offline")
            } else {
                NSLog("%@", error.debugDescription)
                
                // TODO: Alert
                Notification.post(TwitterAuthorizeNotification)
            }
        }
        
        let success = { (accessToken: SwifterCredential.OAuthAccessToken?, response: NSURLResponse) -> Void in
            if let token = accessToken {
                Twitter.refreshAccounts([
                    Account(
                        credential: SwifterCredential(accessToken: token),
                        userID: token.userID!,
                        screenName: token.screenName ?? "",
                        name: token.screenName! ?? "",
                        profileImageURL: NSURL())
                    ])
            } else {
                Notification.post(TwitterAuthorizeNotification)
            }
        }
        
        swifter.authorizeWithCallbackURL(NSURL(string: "justaway://success")!, success: success, failure: failure)
    }
    
    class func refreshAccounts(newAccounts: [Account]) {
        var accounts = [Account]()
        var current = 0
        
        if let accountSettings = AccountSettingsStore.get() {
            
            // Merge accounts and newAccounts
            var newAccountMap = [String: Account]()
            for newAccount in newAccounts {
                newAccountMap[newAccount.userID] = newAccount
            }
            
            accounts = accountSettings.accounts.map({ newAccountMap.removeValueForKey($0.userID) ?? $0 })
            
            for newAccount in newAccountMap.values {
                accounts.insert(newAccount, atIndex: 0)
            }
            
            // Update current index
            let currentUserID = accountSettings.account().userID
            for i in 0 ... accounts.count {
                if accounts[i].userID == currentUserID {
                    current = i
                    break
                }
            }
            
            // Update credential from current account
            swifter.client.credential = accountSettings.account().credential
        } else if newAccounts.count > 0 {
            
            // Merge accounts and newAccounts
            accounts = newAccounts
            
            // Update credential from newAccounts
            swifter.client.credential = accounts[0].credential
        } else {
            return
        }
        
        let userIDs = accounts.map({ $0.userID })
        
        let success :(([JSONValue]?) -> Void) = { (rows: [JSONValue]?) in
            
            // Convert JSONValue
            var userDirectory = [String: TwitterUser]()
            for row in rows! {
                let user = TwitterUser(row)
                userDirectory[user.userID] = user
            }
            
            // Update accounts information
            accounts = accounts.map({ (account: Account) in
                if let user = userDirectory[account.userID] {
                    return Account(
                        credential: account.credential,
                        userID: user.userID,
                        screenName: user.screenName,
                        name: user.name,
                        profileImageURL: user.profileImageURL)
                } else {
                    return account
                }
            })
            
            // Save Device
            AccountSettingsStore.save(AccountSettings(current: current, accounts: accounts))
            
            Notification.post(TwitterAuthorizeNotification)
        }
        
        let failure = { (error: NSError) -> Void in
            
            NSLog("%@", error.debugDescription)
        }
        
        swifter.getUsersLookupWithUserIDs(userIDs, includeEntities: false, success: success, failure: failure)
    }
    
    class func getHomeTimeline(maxID: String?, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        if let account = AccountSettingsStore.get() {
            
            let s = { (array: [JSONValue]?) -> Void in
                if let statuses = array {
                    success(statuses.map { TwitterStatus($0) })
                }
            }
            
            let f = { (error: NSError) -> Void in
                if error.code == 401 {
                    NSLog("%@", "[FATAL] Please set a Your Twitter Consumer Key and Secret for the Secret.swift")
                } else if error.code == 429 {
                    NSLog("%@", "[FATAL] API Limit")
                } else {
                    NSLog("%@", error.debugDescription)
                    
                    // TODO: Alert
                }
                failure(error)
            }
            
            getClient(account.account()).getStatusesHomeTimelineWithCount(nil, sinceID: nil, maxID: maxID, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: s, failure: f)
        }
    }
    
}
