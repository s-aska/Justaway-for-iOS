import UIKit
import SwifteriOS
import EventBox

let TwitterAuthorizeNotification = "TwitterAuthorizeNotification"

class Twitter {
    
    // MARK: - Types
    
    enum ConnectionStatus {
        case CONNECTING
        case CONNECTIED
        case DISCONNECTING
        case DISCONNECTIED
    }
    
    enum Event: String {
        case CreateStatus = "CreateStatus"
        case CreateFavorites = "CreateFavorites"
        case DestroyFavorites = "DestroyFavorites"
        case CreateRetweet = "CreateRetweet"
        case DestroyRetweet = "DestroyRetweet"
    }
    
    struct Static {
        static let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        static var enableStreaming = false
        static var connectionStatus: ConnectionStatus = .DISCONNECTIED
        static var streamingRequest: SwifterHTTPRequest?
        static var favorites = [String: Bool]()
        private static let connectionQueue = dispatch_queue_create("pw.aska.justaway.twitter.connection", DISPATCH_QUEUE_SERIAL)
        private static let favoritesQueue = dispatch_queue_create("pw.aska.justaway.twitter.favorites", DISPATCH_QUEUE_SERIAL)
        private static let retweetsQueue = dispatch_queue_create("pw.aska.justaway.twitter.retweets", DISPATCH_QUEUE_SERIAL)
    }
    
    class var swifter : Swifter { return Static.swifter }
    
    // MARK: - Class Methods
    
    class func setup() {
        let reachability = Reachability.reachabilityForInternetConnection()
        reachability.whenReachable = { reachability in
            Twitter.startStreamingIfEnable()
        }
//        reachability.whenUnreachable = { reachability in
//            println("Not reachable")
//        }
        
        reachability.startNotifier()
    }
    
    class func getClient(account: Account) -> Swifter {
        if let ac = account.credential.account {
            return Swifter(account: ac)
        } else {
            swifter.client.credential = account.credential
            return swifter
        }
    }
    
    class func getClient() -> Swifter? {
        if let account = AccountSettingsStore.get() {
            return getClient(account.account())
        } else {
            return nil
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
                EventBox.post(TwitterAuthorizeNotification)
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
                EventBox.post(TwitterAuthorizeNotification)
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
        
        let success :(([JSONValue]?) -> Void) = { (rows) in
            
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
            
            EventBox.post(TwitterAuthorizeNotification)
        }
        
        let failure = { (error: NSError) -> Void in
            
            NSLog("%@", error.debugDescription)
        }
        
        swifter.getUsersLookupWithUserIDs(userIDs, includeEntities: false, success: success, failure: failure)
    }
    
    class func getHomeTimeline(maxID: String?, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
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
        
        getClient()?.getStatusesHomeTimelineWithCount(200, sinceID: nil, maxID: maxID, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: s, failure: f)
    }
}

// MARK: - REST API

extension Twitter {
    class func toggleFavorite(statusID: String) {
        Async.customQueue(Static.favoritesQueue) {
            if Static.favorites[statusID] == true {
                Twitter.destroyFavorite(statusID)
            } else {
                Async.background {
                    Twitter.createFavorite(statusID)
                }
            }
        }
    }
    
    class func createFavorite(statusID: String) {
        Async.customQueue(Static.favoritesQueue) {
            if Static.favorites[statusID] == true {
                NSLog("aleady favorites")
                return
            }
            Static.favorites[statusID] = true
            EventBox.post(Event.CreateFavorites.rawValue, sender: statusID)
            NSLog("create favorites")
Twitter.getClient()?.postCreateFavoriteWithID(statusID, includeEntities: false, success: { (status) -> Void in
    NSLog("create favorites success")
}, failure: { (error) -> Void in
    let code = Twitter.getErrorCode(error)
    if code == 139 {
        NSLog("aleady favorites failure code:%i", code)
        return
    }
    Async.customQueue(Static.favoritesQueue) {
        NSLog("create favorites failure code:%i error:\(error)", code)
        Static.favorites.removeValueForKey(statusID)
        EventBox.post(Event.DestroyFavorites.rawValue, sender: statusID)
    }
    return
})
        }
    }
    
    class func destroyFavorite(statusID: String) {
        Async.customQueue(Static.favoritesQueue) {
            if Static.favorites[statusID] == nil {
                NSLog("no favorites")
                return
            }
            Static.favorites.removeValueForKey(statusID)
            EventBox.post(Event.DestroyFavorites.rawValue, sender: statusID)
            NSLog("destroy favorites")
            Twitter.getClient()?.postDestroyFavoriteWithID(statusID, includeEntities: false, success: { (status) -> Void in
                NSLog("destroy favorites success")
                }, failure: { (error) -> Void in
                    let code = Twitter.getErrorCode(error)
                    if code == 34 {
                        NSLog("no favorites failure code:%i", code)
                        return
                    }
                    Async.customQueue(Static.favoritesQueue) {
                        NSLog("destroy favorites failure code:%s error:\(error)", code)
                        Static.favorites[statusID] = true
                        EventBox.post(Event.CreateFavorites.rawValue, sender: statusID)
                    }
                    return
            })
        }
    }
    
    class func getErrorCode(error: NSError) -> Int {
        if let userInfo = error.userInfo {
            if let errorCode = userInfo["Response-ErrorCode"] as? Int {
                return errorCode
            }
        }
        return 0
    }
}

// MARK: - Streaming

extension Twitter {
    class func startStreamingIfEnable() {
        if Static.enableStreaming {
            startStreamingIfDisconnected()
        }
    }
    
    class func startStreamingAndEnable() {
        Static.enableStreaming = true
        startStreamingIfDisconnected()
    }
    
    class func startStreamingIfDisconnected() {
        Async.customQueue(Static.connectionQueue) {
            if Static.connectionStatus == .DISCONNECTIED {
                Static.connectionStatus = .CONNECTING
                NSLog("connectionStatus: CONNECTING")
                Twitter.startStreaming()
            }
        }
    }
    
    class func startStreaming() {
        let progress = {
            (data: [String: JSONValue]?) -> Void in
            
            if Static.connectionStatus != .CONNECTIED {
                Static.connectionStatus = .CONNECTIED
                NSLog("connectionStatus: CONNECTIED")
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
            
            if data == nil {
                return
            }
            
            let responce = JSON.JSONObject(data!)
            
            if let event = responce["event"].object {
                
            } else if let delete = responce["delete"].object {
            } else if let status = responce["delete"]["status"].object {
            } else if let direct_message = responce["delete"]["direct_message"].object {
            } else if let direct_message = responce["direct_message"].object {
            } else if let text = responce["text"].string {
                EventBox.post(Event.CreateStatus.rawValue, sender: TwitterStatus(responce))
            }
        }
        let stallWarningHandler = {
            (code: String?, message: String?, percentFull: Int?) -> Void in
            
            println("code:\(code) message:\(message) percentFull:\(percentFull)")
        }
        let failure = {
            (error: NSError) -> Void in
            
            Static.connectionStatus = .DISCONNECTIED
            NSLog("connectionStatus: DISCONNECTIED")
            
            println(error)
        }
        Static.streamingRequest = getClient()?.getUserStreamDelimited(nil,
            stallWarnings: nil,
            includeMessagesFromFollowedAccounts: nil,
            includeReplies: nil,
            track: nil,
            locations: nil,
            stringifyFriendIDs: nil,
            progress: progress,
            stallWarningHandler: stallWarningHandler,
            failure: failure)
    }
    
    class func stopStreamingAndDisable() {
        Static.enableStreaming = false
        stopStreamingIFConnected()
    }
    
    class func stopStreamingIFConnected() {
        Async.customQueue(Static.connectionQueue) {
            if Static.connectionStatus == .CONNECTIED {
                Static.connectionStatus = .DISCONNECTIED
                NSLog("connectionStatus: DISCONNECTIED")
                Twitter.stopStreaming()
            }
        }
    }
    
    class func stopStreaming() {
        Static.streamingRequest?.stop()
    }
}
