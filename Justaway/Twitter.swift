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
        case DestroyStatus = "DestroyStatus"
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
        if let reachability = Reachability.reachabilityForInternetConnection() {
            reachability.whenReachable = { reachability in
                NSLog("whenReachable")
                Async.main(after: 2) {
                    Twitter.startStreamingIfEnable()
                }
                return
            }
            
            reachability.whenUnreachable = { reachability in
                NSLog("whenUnreachable")
            }
            
            reachability.startNotifier()
        }
        
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
    
    class func getUserTimeline(userID: String, maxID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        let s = { (array: [JSONValue]?) -> Void in
            
            if let statuses = array?.map({ TwitterStatus($0) }) {
                success(statuses)
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
        
        getCurrentClient()?.getStatusesUserTimelineWithUserID(userID, maxID: maxID, count: 200, success: s, failure: f)
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
        
        getCurrentClient()?.getStatusesMentionTimelineWithCount(200, sinceID: nil, maxID: maxID, trimUser: nil, contributorDetails: nil, includeEntities: nil, success: s, failure: f)
    }
    
    class func getFavorites(userID: String, maxID: String?, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        let s = { (statuses: [JSONValue]?) -> Void in
            if let statuses = statuses?.map({ TwitterStatus($0) }) {
                success(statuses)
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
        
        getCurrentClient()?.getFavoritesListWithUserID(userID, count: 200, sinceID: nil, maxID: maxID, success: s, failure: f)
    }
    
    class func getFriendships(targetID: String, success: (TwitterRelationship) -> Void, failure: (NSError) -> Void) {
        let s = { (dictionary: Dictionary<String, JSONValue>?) -> Void in
            if let source = dictionary?["relationship"]?["source"] {
                let relationship = TwitterRelationship(source)
                success(relationship)
            }
        }
        
        let f = { (error: NSError) -> Void in
            ErrorAlert.show("Show friendships failure", message: error.localizedDescription)
            failure(error)
        }
        
        if let account = AccountSettingsStore.get() {
            getClient(account.account()).getFriendshipsShowWithSourceID(account.account().userID, targetID: targetID, success: s, failure: f)
        }
    }
    
    class func getFollowingUsers(userID: String, success: ([TwitterUserFull]) -> Void, failure: (NSError) -> Void) {
        let s = { (users: [JSONValue]?, previousCursor: String?, nextCursor: String?) -> Void in
            if let users = users?.map({ TwitterUserFull($0) }) {
                success(users)
            }
        }
        
        let f = { (error: NSError) -> Void in
            ErrorAlert.show("get following failure", message: error.localizedDescription)
            failure(error)
        }
        
        getCurrentClient()?.getFriendsListWithID(userID, cursor: nil, count: 200, skipStatus: nil, includeUserEntities: nil, success: s, failure: f)
    }
    
    class func getFollowerUsers(userID: String, success: ([TwitterUserFull]) -> Void, failure: (NSError) -> Void) {
        let s = { (users: [JSONValue]?, previousCursor: String?, nextCursor: String?) -> Void in
            if let users = users?.map({ TwitterUserFull($0) }) {
                success(users)
            }
        }
        
        let f = { (error: NSError) -> Void in
            ErrorAlert.show("get follower failure", message: error.localizedDescription)
            failure(error)
        }
        
        getCurrentClient()?.getFollowersListWithID(userID, cursor: nil, count: 200, skipStatus: nil, includeUserEntities: nil, success: s, failure: f)
    }
    
    class func getListsMemberOf(userID: String, success: ([TwitterList]) -> Void, failure: (NSError) -> Void) {
        let s = { (lists: [JSONValue]?, previousCursor: String?, nextCursor: String?) -> Void in
            if let lists = lists?.map({ TwitterList($0) }) {
                success(lists)
            }
        }
        
        let f = { (error: NSError) -> Void in
            ErrorAlert.show("get follower failure", message: error.localizedDescription)
            failure(error)
        }
        
        getCurrentClient()?.getListsMembershipsWithUserID(userID, cursor: nil, filterToOwnedLists: nil, success: s, failure: f)
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
        let mentions = " ".join(status.mentions.map({ "@\($0.screenName)" }))
        let range = NSMakeRange(prefix.characters.count, mentions.characters.count)
        EditorViewController.show(prefix + mentions, range: range, inReplyToStatusId: status.statusID)
    }
    
    class func quoteURL(status: TwitterStatus) {
        EditorViewController.show(" \(status.statusURL)", range: NSMakeRange(0, 0), inReplyToStatusId: status.statusID)
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
                        ErrorAlert.show("Undo Retweet failure", message: "missing retweets.")
                    } else {
                        Async.customQueue(Static.retweetsQueue) {
                            Static.retweets[statusID] = retweetedStatusID
                            EventBox.post(Event.CreateRetweet.rawValue, sender: statusID)
                        }
                        ErrorAlert.show("Undo Retweet failure", message: error.localizedDescription)
                    }
            })
        }
    }
    
    class func destroyStatus(account: Account, statusID: String) {
        Twitter.getClient(account).postStatusesDestroyWithID(statusID, success: { (status) -> Void in
        }, failure: { (error) -> Void in
            let code = Twitter.getErrorCode(error)
            ErrorAlert.show("Undo Tweet failure code:\(code)", message: error.localizedDescription)
        })
    }
    
    class func follow(userID: String) {
        getCurrentClient()?.postCreateFriendshipWithID(userID, follow: nil, success: { (user) -> Void in
            ErrorAlert.show("Follow success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Follow failure", message: error.localizedDescription)
        })
    }
    
    class func unfollow(userID: String) {
        getCurrentClient()?.postDestroyFriendshipWithID(userID, success: { (user) -> Void in
            ErrorAlert.show("Unfollow success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Unfollow failure", message: error.localizedDescription)
        })
    }
    
    class func turnOnNotification(userID: String) {
        getCurrentClient()?.postUpdateFriendshipWithID(userID, device: true, retweets: nil, success: { (user) -> Void in
            ErrorAlert.show("Turn on notification success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Turn on notification failure", message: error.localizedDescription)
        })
    }
    
    class func turnOffNotification(userID: String) {
        getCurrentClient()?.postUpdateFriendshipWithID(userID, device: false, retweets: nil, success: { (user) -> Void in
            ErrorAlert.show("Turn off notification success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Turn off notification failure", message: error.localizedDescription)
        })
    }
    
    class func turnOnRetweets(userID: String) {
        getCurrentClient()?.postUpdateFriendshipWithID(userID, device: nil, retweets: true, success: { (user) -> Void in
            ErrorAlert.show("Turn on retweets success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Turn on retweets failure", message: error.localizedDescription)
        })
    }
    
    class func turnOffRetweets(userID: String) {
        getCurrentClient()?.postUpdateFriendshipWithID(userID, device: nil, retweets: false, success: { (user) -> Void in
            ErrorAlert.show("Turn off retweets success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Turn off retweets failure", message: error.localizedDescription)
        })
    }
    
    class func mute(userID: String) {
        getCurrentClient()?.postMutesUsersCreateForUserID(userID, success: { (user) -> Void in
            ErrorAlert.show("Mute success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Mute failure", message: error.localizedDescription)
        })
    }
    
    class func unmute(userID: String) {
        getCurrentClient()?.postMutesUsersDestroyForUserID(userID, success: { (user) -> Void in
            ErrorAlert.show("Unmute success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Unmute failure", message: error.localizedDescription)
        })
    }
    
    class func block(userID: String) {
        getCurrentClient()?.postBlocksCreateWithUserID(userID, success: { (user) -> Void in
            ErrorAlert.show("Block success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Block failure", message: error.localizedDescription)
        })
    }
    
    class func unblock(userID: String) {
        getCurrentClient()?.postDestroyBlocksWithUserID(userID, success: { (user) -> Void in
            ErrorAlert.show("Unblock success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Unblock failure", message: error.localizedDescription)
        })
    }
    
    class func reportSpam(userID: String) {
        getCurrentClient()?.postUsersReportSpamWithUserID(userID, success: { (user) -> Void in
            ErrorAlert.show("Report success")
        }, failure: { (error) -> Void in
            ErrorAlert.show("Report failure", message: error.localizedDescription)
        })
    }
    
    class func getErrorCode(error: NSError) -> Int {
        if let errorCode = error.userInfo["Response-ErrorCode"] as? Int {
            return errorCode
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
            
            if responce["event"].string != nil {
                NSLog("event")
                let status = TwitterStatus(responce)
                if let source = status.actionedBy {
                    if AccountSettingsStore.get()?.find(source.userID) != nil {
                        NSLog("by me")
                    } else {
                        NSLog("by other")
                        EventBox.post(Event.CreateStatus.rawValue, sender: status)
                    }
                } else {
                    NSLog("??")
                }
            } else if let statusID = responce["delete"]["status"]["id_str"].string {
                EventBox.post(Event.DestroyStatus.rawValue, sender: statusID)
            } else if responce["delete"]["direct_message"].object != nil {
            } else if responce["direct_message"].object != nil {
            } else if responce["text"].string != nil {
                EventBox.post(Event.CreateStatus.rawValue, sender: TwitterStatus(responce))
            }
        }
        let stallWarningHandler = {
            (code: String?, message: String?, percentFull: Int?) -> Void in
            
            print("code:\(code) message:\(message) percentFull:\(percentFull)")
        }
        let failure = {
            (error: NSError) -> Void in
            
            Static.connectionStatus = .DISCONNECTED
            EventBox.post(Event.StreamingStatusChanged.rawValue)
            NSLog("connectionStatus: DISCONNECTED")
            
            print(error)
        }
        
        if Static.backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            NSLog("backgroundTaskIdentifier: beginBackgroundTask")
            Static.backgroundTaskIdentifier = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler() {
                NSLog("backgroundTaskIdentifier: Expiration")
                if Static.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    NSLog("backgroundTaskIdentifier: endBackgroundTask")
                    self.stopStreamingIFConnected()
                    UIApplication.sharedApplication().endBackgroundTask(Static.backgroundTaskIdentifier)
                    Static.backgroundTaskIdentifier = UIBackgroundTaskInvalid
                }
            }
        }
        
        Static.streamingRequest = getCurrentClient()?.getUserStreamDelimited(nil,
            stallWarnings: true,
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
