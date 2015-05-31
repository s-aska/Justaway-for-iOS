import UIKit
import Accounts
import SwifteriOS
import EventBox
import KeyClip

let TwitterAuthorizeNotification = "TwitterAuthorizeNotification"

class Twitter {
    
    // MARK: - Types
    
    enum ConnectionStatus {
        case CONNECTING
        case CONNECTED
        case DISCONNECTING
        case DISCONNECTED
    }
    
    enum Event: String {
        case CreateStatus = "CreateStatus"
        case CreateFavorites = "CreateFavorites"
        case DestroyFavorites = "DestroyFavorites"
        case CreateRetweet = "CreateRetweet"
        case DestroyRetweet = "DestroyRetweet"
        case StreamingStatusChanged = "StreamingStatusChanged"
    }
    
    struct Static {
        static let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        static var enableStreaming = false
        static var connectionStatus: ConnectionStatus = .DISCONNECTED
        static var streamingRequest: SwifterHTTPRequest?
        static var favorites = [String: Bool]()
        static var retweets = [String: String]()
        static var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        private static let connectionQueue = dispatch_queue_create("pw.aska.justaway.twitter.connection", DISPATCH_QUEUE_SERIAL)
        private static let favoritesQueue = dispatch_queue_create("pw.aska.justaway.twitter.favorites", DISPATCH_QUEUE_SERIAL)
        private static let retweetsQueue = dispatch_queue_create("pw.aska.justaway.twitter.retweets", DISPATCH_QUEUE_SERIAL)
    }
    
    class var swifter : Swifter { return Static.swifter }
    class var connectionStatus: ConnectionStatus { return Static.connectionStatus }
    class var enableStreaming: Bool { return Static.enableStreaming }
    
    
    // MARK: - Class Methods
    
    class func setup() {
        let reachability = Reachability.reachabilityForInternetConnection()
        reachability.whenReachable = { reachability in
            Async.main(after: 2) {
                Twitter.startStreamingIfEnable()
            }
            return
        }
        
//        reachability.whenUnreachable = { reachability in
//            println("Not reachable")
//        }
        
        reachability.startNotifier()
        
        let enableStreaming: String = KeyClip.load("settings.enableStreaming") ?? "0"
        if enableStreaming == "1" {
            Static.enableStreaming = true
            Twitter.startStreamingIfDisconnected()
        }
    }
    
    class func getClient(account: Account) -> Swifter {
        if let ac = account.credential.account {
            return Swifter(account: ac)
        } else {
            swifter.client.credential = account.credential
            return swifter
        }
    }
    
    class func getCurrentClient() -> Swifter? {
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
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            } else if error.code == 429 {
                ErrorAlert.show("Tweet failure", message: "API Limit")
            } else {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
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
    
    class func addACAccount() {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        // Prompt the user for permission to their twitter account stored in the phone's settings
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                
                if twitterAccounts.count == 0 {
                    MessageAlert.show("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                } else {
                    Twitter.refreshAccounts(
                        twitterAccounts.map({ (twitterAccount: ACAccount) in
                            Account(
                                credential: SwifterCredential(account: twitterAccount),
                                userID: twitterAccount.valueForKeyPath("properties.user_id") as! String,
                                screenName: twitterAccount.username,
                                name: twitterAccount.username,
                                profileImageURL: NSURL(string: "")!)
                        })
                    )
                }
            } else {
                MessageAlert.show("Error", message: error.localizedDescription)
            }
        }
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
    
    class func getHomeTimelineCache(success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        Async.background {
            if let cache = KeyClip.load("homeTimeline") as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                    success(statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success([TwitterStatus]())
        }
    }
    
    class func getHomeTimeline(maxID: String?, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        let s = { (array: [JSONValue]?) -> Void in
            
            if let statuses = array?.map({ TwitterStatus($0) }) {
                
                success(statuses)
                
                if maxID == nil {
                    let dictionary = ["statuses": statuses.map({ $0.dictionaryValue })]
                    if KeyClip.save("homeTimeline", dictionary: dictionary) {
                        NSLog("homeTimeline cache success.")
                    }
                }
            }
        }
        
        let f = { (error: NSError) -> Void in
            if error.code == 401 {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            } else if error.code == 429 {
                ErrorAlert.show("Tweet failure", message: "API Limit")
            } else {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            }
            failure(error)
        }
        
        getCurrentClient()?.getStatusesHomeTimelineWithCount(200, sinceID: nil, maxID: maxID, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: s, failure: f)
    }
    
    class func getMentionTimelineCache(success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        Async.background {
            if let cache = KeyClip.load("mentionTimeline") as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                    success(statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success([TwitterStatus]())
        }
    }
    
    class func getMentionTimeline(maxID: String?, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        let s = { (array: [JSONValue]?) -> Void in
            
            if let statuses = array?.map({ TwitterStatus($0) }) {
                
                success(statuses)
                
                if maxID == nil {
                    let dictionary = ["statuses": statuses.map({ $0.dictionaryValue })]
                    if KeyClip.save("mentionTimeline", dictionary: dictionary) {
                        NSLog("mentionTimeline cache success.")
                    }
                }
            }
        }
        
        let f = { (error: NSError) -> Void in
            if error.code == 401 {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            } else if error.code == 429 {
                ErrorAlert.show("Tweet failure", message: "API Limit")
            } else {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            }
            failure(error)
        }
        
        getCurrentClient()?.getStatusesMentionTimelineWithCount(count: 200, sinceID: nil, maxID: maxID, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: s, failure: f)
    }
    
    class func statusUpdate(status: String, inReplyToStatusID: String?, var images: [NSData], var media_ids: [String]) {
        if images.count == 0 {
            return statusUpdate(status, inReplyToStatusID: inReplyToStatusID, media_ids: media_ids)
        }
        
        let image = images.removeAtIndex(0)
        
        let f = { (error: NSError) -> Void in
            if error.code == 401 {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            } else if error.code == 429 {
                ErrorAlert.show("Tweet failure", message: "API Limit")
            } else {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            }
        }
        
        let s = { (res: [String: JSONValue]?) -> Void in
            if let media_id = res?["media_id_string"]?.string {
                media_ids.append(media_id)
            }
            self.statusUpdate(status, inReplyToStatusID: inReplyToStatusID, images: images, media_ids: media_ids)
        }
        
        getCurrentClient()?.postMedia(image, success: s, failure: f)
    }
    
    class func statusUpdate(status: String, inReplyToStatusID: String?, media_ids: [String]) {
        
        let s = { (status: [String: JSONValue]?) -> Void in
        }
        
        let f = { (error: NSError) -> Void in
            if error.code == 401 {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            } else if error.code == 429 {
                ErrorAlert.show("Tweet failure", message: "API Limit")
            } else {
                ErrorAlert.show("Tweet failure", message: error.localizedDescription)
            }
        }
        
        getCurrentClient()?.postStatusUpdate(status, inReplyToStatusID: inReplyToStatusID, media_ids: media_ids, success: s, failure: f)
    }
}

// MARK: - Virtual

extension Twitter {
    
    class func reply(status: TwitterStatus) {
        let prefix = "@\(status.user.screenName) "
        let mentions = join(" ", status.mentions.map({ "@\($0.screenName)" }))
        let range = NSMakeRange(count(prefix), count(mentions))
        EditorEvent(text: prefix + mentions, range: range, inReplyToStatusId: status.statusID).post()
    }
    
    class func quoteURL(status: TwitterStatus) {
        EditorEvent(text: " \(status.statusURL)", range: NSMakeRange(0, 0), inReplyToStatusId: status.statusID).post()
    }
    
}

// MARK: - REST API

extension Twitter {
    
    class func isFavorite(statusID: String, handler: (Bool) -> Void) {
        Async.customQueue(Static.favoritesQueue) {
            handler(Static.favorites[statusID] == true)
        }
    }
    
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
                ErrorAlert.show("Favorite failure", message: "already favorite.")
                return
            }
            Static.favorites[statusID] = true
            EventBox.post(Event.CreateFavorites.rawValue, sender: statusID)
            Twitter.getCurrentClient()?.postCreateFavoriteWithID(statusID, includeEntities: false, success: { (status) -> Void in
            }, failure: { (error) -> Void in
                let code = Twitter.getErrorCode(error)
                if code == 139 {
                    ErrorAlert.show("Favorite failure", message: "already favorite.")
                } else {
                    Async.customQueue(Static.favoritesQueue) {
                        Static.favorites.removeValueForKey(statusID)
                        EventBox.post(Event.DestroyFavorites.rawValue, sender: statusID)
                    }
                    ErrorAlert.show("Favorite failure", message: error.localizedDescription)
                }
            })
        }
    }
    
    class func destroyFavorite(statusID: String) {
        Async.customQueue(Static.favoritesQueue) {
            if Static.favorites[statusID] == nil {
                ErrorAlert.show("Unfavorite failure", message: "missing favorite.")
                return
            }
            Static.favorites.removeValueForKey(statusID)
            EventBox.post(Event.DestroyFavorites.rawValue, sender: statusID)
            Twitter.getCurrentClient()?.postDestroyFavoriteWithID(statusID, includeEntities: false, success: { (status) -> Void in
            }, failure: { (error) -> Void in
                    let code = Twitter.getErrorCode(error)
                    if code == 34 {
                        ErrorAlert.show("Unfavorite failure", message: "missing favorite.")
                    } else {
                        Async.customQueue(Static.favoritesQueue) {
                            Static.favorites[statusID] = true
                            EventBox.post(Event.CreateFavorites.rawValue, sender: statusID)
                        }
                        ErrorAlert.show("Unfavorite failure", message: error.localizedDescription)
                    }
            })
        }
    }
    
    class func isRetweet(statusID: String, handler: (String?) -> Void) {
        Async.customQueue(Static.retweetsQueue) {
            handler(Static.retweets[statusID])
        }
    }
    
    class func createRetweet(statusID: String) {
        Async.customQueue(Static.retweetsQueue) {
            if Static.retweets[statusID] != nil {
                ErrorAlert.show("Retweet failure", message: "already retweets.")
                return
            }
            Static.retweets[statusID] = "0"
            EventBox.post(Event.CreateRetweet.rawValue, sender: statusID)
            Twitter.getCurrentClient()?.postStatusRetweetWithID(statusID, trimUser: nil, success: { (status: [String : JSONValue]?) -> Void in
                Async.customQueue(Static.retweetsQueue) {
                    if let id = status?["id_str"]?.string {
                        Static.retweets[statusID] = id
                    }
                }
                return
            }, failure: { (error) -> Void in
                let code = Twitter.getErrorCode(error)
                if code == 34 {
                    ErrorAlert.show("Retweet failure", message: "already retweets.")
                } else {
                    Async.customQueue(Static.retweetsQueue) {
                        Static.retweets.removeValueForKey(statusID)
                        EventBox.post(Event.DestroyRetweet.rawValue, sender: statusID)
                    }
                    ErrorAlert.show("Retweet failure", message: error.localizedDescription)
                }
            })
        }
    }
    
    class func destroyRetweet(statusID: String, retweetedStatusID: String) {
        Async.customQueue(Static.retweetsQueue) {
            if Static.retweets[statusID] == nil {
                ErrorAlert.show("Unod Retweet failure", message: "missing retweets.")
                return
            }
            Static.retweets.removeValueForKey(statusID)
            EventBox.post(Event.DestroyRetweet.rawValue, sender: statusID)
            Twitter.getCurrentClient()?.postStatusesDestroyWithID(retweetedStatusID, trimUser: nil, success: { (status) -> Void in
            }, failure: { (error) -> Void in
                    let code = Twitter.getErrorCode(error)
                    if code == 34 {
                        ErrorAlert.show("Unod Retweet failure", message: "missing retweets.")
                    } else {
                        Async.customQueue(Static.retweetsQueue) {
                            Static.retweets[statusID] = retweetedStatusID
                            EventBox.post(Event.CreateRetweet.rawValue, sender: statusID)
                        }
                        ErrorAlert.show("Unod Retweet failure", message: error.localizedDescription)
                    }
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
        KeyClip.save("settings.enableStreaming", string: "1")
    }
    
    class func startStreamingIfDisconnected() {
        Async.customQueue(Static.connectionQueue) {
            if Static.connectionStatus == .DISCONNECTED {
                Static.connectionStatus = .CONNECTING
                EventBox.post(Event.StreamingStatusChanged.rawValue)
                NSLog("connectionStatus: CONNECTING")
                Twitter.startStreaming()
            }
        }
    }
    
    class func startStreaming() {
        let progress = {
            (data: [String: JSONValue]?) -> Void in
            
            if Static.connectionStatus != .CONNECTED {
                Static.connectionStatus = .CONNECTED
                EventBox.post(Event.StreamingStatusChanged.rawValue)
                NSLog("connectionStatus: CONNECTED")
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
            
            Static.connectionStatus = .DISCONNECTED
            EventBox.post(Event.StreamingStatusChanged.rawValue)
            NSLog("connectionStatus: DISCONNECTED")
            
            println(error)
        }
        
        if Static.backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            Static.backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler() {
                if Static.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    UIApplication.sharedApplication().endBackgroundTask(Static.backgroundTaskIdentifier)
                    Static.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                }
            }
        }
        
        Static.streamingRequest = getCurrentClient()?.getUserStreamDelimited(delimited: nil,
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
        KeyClip.save("settings.enableStreaming", string: "0")
    }
    
    class func stopStreamingIFConnected() {
        Async.customQueue(Static.connectionQueue) {
            if Static.connectionStatus == .CONNECTED {
                Static.connectionStatus = .DISCONNECTED
                EventBox.post(Event.StreamingStatusChanged.rawValue)
                NSLog("connectionStatus: DISCONNECTED")
                Twitter.stopStreaming()
            }
        }
    }
    
    class func stopStreaming() {
        Static.streamingRequest?.stop()
    }
}
