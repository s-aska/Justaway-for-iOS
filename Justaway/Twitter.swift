import Foundation
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
    
    enum StreamingEvent: String {
        case CreateStatus = "CreateStatus"
    }
    
    struct Static {
        static let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        static var enableStreaming = false
        static var connectionStatus: ConnectionStatus = .DISCONNECTIED
        static var streamingRequest: SwifterHTTPRequest?
        private static let serial = dispatch_queue_create("pw.aska.justaway.twitter.serial", DISPATCH_QUEUE_SERIAL)
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
            
            getClient(account.account()).getStatusesHomeTimelineWithCount(200, sinceID: nil, maxID: maxID, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: s, failure: f)
        }
    }
    
    class func startStreamingIfEnable() {
        if Static.enableStreaming {
            startStreaming()
        }
    }
    
    class func startStreamingAndEnable() {
        Static.enableStreaming = true
        startStreaming()
    }
    
    class func startStreaming() {
        dispatch_sync(Static.serial) {
            if Static.connectionStatus == .DISCONNECTIED {
                Static.connectionStatus = .CONNECTING
                NSLog("connectionStatus: CONNECTING")
            } else {
                return
            }
        }
        let progress = {
            (data: [String: JSONValue]?) -> Void in
            
            if Static.connectionStatus != .CONNECTIED {
                Static.connectionStatus = .CONNECTIED
                NSLog("connectionStatus: CONNECTIED")
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
                EventBox.post(StreamingEvent.CreateStatus.rawValue, sender: TwitterStatus(responce))
            }
            
            //            println(responce)
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
        if let account = AccountSettingsStore.get() {
            Static.streamingRequest = Twitter.getClient(account.account()).getUserStreamDelimited(nil,
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
    }
    
    class func stopStreamingAndDisable() {
        Static.enableStreaming = false
        stopStreaming()
    }
    
    class func stopStreaming() {
        dispatch_sync(Static.serial) {
            if Static.connectionStatus == .CONNECTIED {
                Static.connectionStatus = .DISCONNECTIED
                NSLog("connectionStatus: DISCONNECTIED")
            } else {
                return
            }
        }
        Static.streamingRequest?.stop()
    }
}
