import UIKit
import Accounts
import EventBox
import KeyClip
import OAuthSwift
import SwiftyJSON

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
        static var enableStreaming = false
        static var connectionStatus: ConnectionStatus = .DISCONNECTED
        static var streamingRequest: TwitterAPI.StreamingRequest?
        static var favorites = [String: Bool]()
        static var retweets = [String: String]()
        static var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        private static let connectionQueue = dispatch_queue_create("pw.aska.justaway.twitter.connection", DISPATCH_QUEUE_SERIAL)
        private static let favoritesQueue = dispatch_queue_create("pw.aska.justaway.twitter.favorites", DISPATCH_QUEUE_SERIAL)
        private static let retweetsQueue = dispatch_queue_create("pw.aska.justaway.twitter.retweets", DISPATCH_QUEUE_SERIAL)
    }
    
    class var connectionStatus: ConnectionStatus { return Static.connectionStatus }
    class var enableStreaming: Bool { return Static.enableStreaming }
    
    
    // MARK: - Class Methods
    
    class func setup() {
        if let reachability = Reachability.reachabilityForInternetConnection() {
            reachability.whenReachable = { reachability in
                NSLog("whenReachable")
//                Async.main(after: 2) {
//                    Twitter.startStreamingIfEnable()
//                }
//                return
            }
            
            reachability.whenUnreachable = { reachability in
                NSLog("whenUnreachable")
            }
            
            reachability.startNotifier()
        }
        
        let enableStreaming: String = KeyClip.load("settings.enableStreaming") ?? "0"
        if enableStreaming == "1" {
//            Static.enableStreaming = true
//            Twitter.startStreamingIfDisconnected()
        }
    }
    
    class func addOAuthAccount() {
        let failure: ((NSError) -> Void) = {
            error in
            
            if error.code == 401 {
                ErrorAlert.show("Twitter auth failure", message: error.localizedDescription)
            } else if error.code == 429 {
                ErrorAlert.show("Twitter auth failure", message: "API Limit")
            } else {
                ErrorAlert.show("Twitter auth failure", message: error.localizedDescription)
                EventBox.post(TwitterAuthorizeNotification)
            }
        }
        
        let oauthswift = OAuth1Swift(
            consumerKey:    TwitterConsumerKey,
            consumerSecret: TwitterConsumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        oauthswift.authorizeWithCallbackURL( NSURL(string: "justaway://success")!, success: {
            credential, response in
            
            let credential: TwitterAPICredential = TwitterAPI.CredentialOAuth(
                consumerKey: TwitterConsumerKey,
                consumerSecret: TwitterConsumerSecret,
                accessToken: credential.oauth_token,
                accessTokenSecret: credential.oauth_token_secret)
            
            let url = NSURL(string: "https://api.twitter.com/1.1/account/verify_credentials.json")!
            credential.get(url).send() { (json: JSON) -> Void in
                let user = TwitterUser(json)
                let account = Account(
                    credential: credential,
                    userID: user.userID,
                    screenName: user.screenName,
                    name: user.name,
                    profileImageURL: user.profileImageURL)
                Twitter.refreshAccounts([account])
            }
        }, failure: failure)
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
                        twitterAccounts.map({ (account: ACAccount) in
                            Account(
                                credential: TwitterAPI.credential(account: account),
                                userID: account.valueForKeyPath("properties.user_id") as! String,
                                screenName: account.username,
                                name: account.username,
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
        var credential: TwitterAPICredential?
        
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
            credential = accounts[current].credential
        } else if newAccounts.count > 0 {
            
            // Merge accounts and newAccounts
            accounts = newAccounts
            
            // Update credential from newAccounts
            credential = accounts[0].credential
        } else {
            return
        }
        
        let userIDs = accounts.map({ $0.userID }).joinWithSeparator(",")
        
        let success :(([JSON]) -> Void) = { (rows) in
            
            // Convert JSONValue
            var userDirectory = [String: TwitterUser]()
            for row in rows {
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
        
        let parameters = ["user_id": userIDs]
        let url = NSURL(string: "https://api.twitter.com/1.1/users/lookup.json")!
        credential?.get(url, parameters: parameters).send(success)
    }
    
    class func credential() -> TwitterAPICredential? {
        return AccountSettingsStore.get()?.account().credential
    }
    
    class func getHomeTimeline(maxID maxID: String? = nil, sinceID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        var parameters = [String: String]()
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")!
        credential()?.get(url, parameters: parameters).send { (array: [JSON]) -> Void in
            let statuses = array.map({ TwitterStatus($0) })
            success(statuses)
            if maxID == nil {
                let dictionary = ["statuses": statuses.map({ $0.dictionaryValue })]
                if KeyClip.save("homeTimeline", dictionary: dictionary) {
                    NSLog("homeTimeline cache success.")
                }
            }
        }
    }
    
    class func getStatuses(statusIDs: [String], success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        let parameters = ["id": statusIDs.joinWithSeparator(",")]
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/lookup.json")!
        credential()?.get(url, parameters: parameters).send { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
    }
    
    class func getUserTimeline(userID: String, maxID: String? = nil, sinceID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        var parameters = ["user_id": userID]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/user_timeline.json")!
        credential()?.get(url, parameters: parameters).send { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
    }
    
    class func getMentionTimeline(maxID maxID: String? = nil, sinceID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        var parameters: [String: String] = [:]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/mentions_timeline.json")!
        credential()?.get(url, parameters: parameters).send { (array: [JSON]) -> Void in
            
            let statuses = array.map({ TwitterStatus($0) })
            
            success(statuses)
            
            if maxID == nil {
                let dictionary = ["statuses": statuses.map({ $0.dictionaryValue })]
                if KeyClip.save("mentionTimeline", dictionary: dictionary) {
                    NSLog("mentionTimeline cache success.")
                }
            }
        }
    }
    
    class func getFavorites(userID: String, maxID: String? = nil, sinceID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        var parameters = ["user_id": userID]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let url = NSURL(string: "https://api.twitter.com/1.1/favorites/list.json")!
        credential()?.get(url, parameters: parameters).send { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
    }
    
    class func getFriendships(targetID: String, success: (TwitterRelationship) -> Void) {
        guard let account = AccountSettingsStore.get() else {
            return
        }
        let parameters = ["source_id": account.account().userID, "target_id": targetID]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/show.json")!
        credential()?.get(url, parameters: parameters).send { (json: JSON) -> Void in
            if let source: JSON = json["relationship"]["source"] {
                let relationship = TwitterRelationship(source)
                success(relationship)
            }
        }
    }
    
    class func getFollowingUsers(userID: String, success: ([TwitterUserFull]) -> Void, failure: (NSError) -> Void) {
        let parameters = ["user_id": userID, "count": "200"]
        let url = NSURL(string: "https://api.twitter.com/1.1/friends/list.json")!
        credential()?.get(url, parameters: parameters).send { (json: JSON) -> Void in
            if let users = json["users"].array {
                success(users.map({ TwitterUserFull($0) }))
            }
        }
    }
    
    class func getFollowerUsers(userID: String, success: ([TwitterUserFull]) -> Void, failure: (NSError) -> Void) {
        let parameters = ["user_id": userID, "count": "200"]
        let url = NSURL(string: "https://api.twitter.com/1.1/followers/list.json")!
        credential()?.get(url, parameters: parameters).send { (json: JSON) -> Void in
            if let users = json["users"].array {
                success(users.map({ TwitterUserFull($0) }))
            }
        }
    }
    
    class func getListsMemberOf(userID: String, success: ([TwitterList]) -> Void, failure: (NSError) -> Void) {
        let parameters = ["user_id": userID, "count": "200"]
        let url = NSURL(string: "https://api.twitter.com/1.1/lists/memberships.json")!
        credential()?.get(url, parameters: parameters).send { (json: JSON) -> Void in
            if let lists = json["lists"].array {
                success(lists.map({ TwitterList($0) }))
            }
        }
    }
    
    class func statusUpdate(status: String, inReplyToStatusID: String?, var images: [NSData], var media_ids: [String]) {
        if images.count == 0 {
            return statusUpdate(status, inReplyToStatusID: inReplyToStatusID, media_ids: media_ids)
        }
        let image = images.removeAtIndex(0)
        Async.background { () -> Void in
            credential()?.postMedia(image).send { (json: JSON) -> Void in
                if let media_id = json["media_id_string"].string {
                    media_ids.append(media_id)
                }
                self.statusUpdate(status, inReplyToStatusID: inReplyToStatusID, images: images, media_ids: media_ids)
            }
        }
    }
    
    class func statusUpdate(status: String, inReplyToStatusID: String?, media_ids: [String]) {
        var parameters = [String: String]()
        parameters["status"] = status
        if let inReplyToStatusID = inReplyToStatusID {
            parameters["in_reply_to_status_id"] = inReplyToStatusID
        }
        if media_ids.count > 0 {
            parameters["media_ids"] = media_ids.joinWithSeparator(",")
        }
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            
        })
    }
}

// MARK: - Virtual

extension Twitter {
    
    class func reply(status: TwitterStatus) {
        if let account = AccountSettingsStore.get()?.account() {
            let prefix = "@\(status.user.screenName) "
            var users = status.mentions
            if let actionedBy = status.actionedBy {
                users.append(actionedBy)
            }
            let mentions = users.filter({ $0.userID != status.user.userID && account.userID != $0.userID }).map({ "@\($0.screenName) " }).joinWithSeparator("")
            let range = NSMakeRange(prefix.characters.count, mentions.characters.count)
            EditorViewController.show(prefix + mentions, range: range, inReplyToStatus: status)
        }
    }
    
    class func quoteURL(status: TwitterStatus) {
        EditorViewController.show(" \(status.statusURL)", range: NSMakeRange(0, 0), inReplyToStatus: status)
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
            let parameters = ["id": statusID]
            let url = NSURL(string: "https://api.twitter.com/1.1/favorites/create.json")!
            credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
                
                }, failure: { (code, message, error) -> Void in
                    if code == 139 {
                        ErrorAlert.show("Favorite failure", message: "already favorite.")
                    } else {
                        Async.customQueue(Static.favoritesQueue) {
                            Static.favorites.removeValueForKey(statusID)
                            EventBox.post(Event.DestroyFavorites.rawValue, sender: statusID)
                        }
                        ErrorAlert.show("Favorite failure", message: message ?? error?.localizedDescription)
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
            let parameters = ["id": statusID]
            let url = NSURL(string: "https://api.twitter.com/1.1/favorites/destroy.json")!
            credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
                
                }, failure: { (code, message, error) -> Void in
                    if code == 34 {
                        ErrorAlert.show("Unfavorite failure", message: "missing favorite.")
                    } else {
                        Async.customQueue(Static.favoritesQueue) {
                            Static.favorites[statusID] = true
                            EventBox.post(Event.CreateFavorites.rawValue, sender: statusID)
                        }
                        ErrorAlert.show("Unfavorite failure", message: message ?? error?.localizedDescription)
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
            let url = NSURL(string: "https://api.twitter.com/1.1/statuses/retweet/\(statusID).json")!
            credential()?.post(url).send({ (json: JSON) -> Void in
                Async.customQueue(Static.retweetsQueue) {
                    if let id = json["id_str"].string {
                        Static.retweets[statusID] = id
                    }
                }
                return
            }, failure: { (code, message, error) -> Void in
                if code == 34 {
                    ErrorAlert.show("Retweet failure", message: "already retweets.")
                } else {
                    Async.customQueue(Static.retweetsQueue) {
                        Static.retweets.removeValueForKey(statusID)
                        EventBox.post(Event.DestroyRetweet.rawValue, sender: statusID)
                    }
                    ErrorAlert.show("Retweet failure", message: message ?? error?.localizedDescription)
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
            let url = NSURL(string: "https://api.twitter.com/1.1/statuses/destroy/\(retweetedStatusID).json")!
            credential()?.post(url, parameters: [:]).send({ (json: JSON) -> Void in
            }, failure: { (code, message, error) -> Void in
                    if code == 34 {
                        ErrorAlert.show("Undo Retweet failure", message: "missing retweets.")
                    } else {
                        Async.customQueue(Static.retweetsQueue) {
                            Static.retweets[statusID] = retweetedStatusID
                            EventBox.post(Event.CreateRetweet.rawValue, sender: statusID)
                        }
                        ErrorAlert.show("Undo Retweet failure", message: message ?? error?.localizedDescription)
                    }
            })
        }
    }
    
    class func destroyStatus(account: Account, statusID: String) {
        let url = NSURL(string: "https://api.twitter.com/1.1/statuses/destroy/\(statusID).json")!
        account.credential.post(url).send({ (json: JSON) -> Void in
        }, failure: { (code, message, error) -> Void in
            ErrorAlert.show("Undo Tweet failure code:\(code)", message: message ?? error?.localizedDescription)
        })
    }
    
    class func follow(userID: String) {
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/create.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Follow success")
        })
    }
    
    class func unfollow(userID: String) {
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/destroy.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Unfollow success")
        })
    }
    
    class func turnOnNotification(userID: String) {
        let parameters = ["user_id": userID, "device": "true"]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/update.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Turn on notification success")
        })
    }
    
    class func turnOffNotification(userID: String) {
        let parameters = ["user_id": userID, "device": "false"]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/update.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Turn off notification success")
        })
    }
    
    class func turnOnRetweets(userID: String) {
        let parameters = ["user_id": userID, "retweets": "true"]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/update.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Turn on retweets success")
        })
    }
    
    class func turnOffRetweets(userID: String) {
        let parameters = ["user_id": userID, "retweets": "false"]
        let url = NSURL(string: "https://api.twitter.com/1.1/friendships/update.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Turn off retweets success")
        })
    }
    
    class func mute(userID: String) { //
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/mutes/users/create.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Mute success")
        })
    }
    
    class func unmute(userID: String) {
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/mutes/users/destroy.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Unmute success")
        })
    }
    
    class func block(userID: String) {
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/mutes/blocks/create.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Block success")
        })
    }
    
    class func unblock(userID: String) {
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/mutes/blocks/destroy.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Unblock success")
        })
    }
    
    class func reportSpam(userID: String) {
        let parameters = ["user_id": userID]
        let url = NSURL(string: "https://api.twitter.com/1.1/users/report_spam.json")!
        credential()?.post(url, parameters: parameters).send({ (json: JSON) -> Void in
            ErrorAlert.show("Report success")
        })
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
            (responce: JSON) -> Void in
            
            if responce["friends"] != nil {
                NSLog("friends is not null")
                if Static.connectionStatus != .CONNECTED {
                    Static.connectionStatus = .CONNECTED
                    EventBox.post(Event.StreamingStatusChanged.rawValue)
                    NSLog("connectionStatus: CONNECTED")
                    // UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
            } else if let event = responce["event"].string {
                NSLog("event:\(event)")
                if event == "favorite" {
                    let status = TwitterStatus(responce)
                    EventBox.post(Event.CreateStatus.rawValue, sender: status)
                    if AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                        Static.favorites[status.statusID] = true
                        EventBox.post(Event.CreateFavorites.rawValue, sender: status.statusID)
                    }
                } else if event == "unfavorite" {
                    let status = TwitterStatus(responce)
                    if AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                        Static.favorites.removeValueForKey(status.statusID)
                        EventBox.post(Event.DestroyFavorites.rawValue, sender: status.statusID)
                    }
                } else if event == "quoted_tweet" || event == "favorited_retweet" || event == "retweeted_retweet" {
                    EventBox.post(Event.CreateStatus.rawValue, sender: TwitterStatus(responce))
                } else if event == "access_revoked" {
                    revoked()
                }
            } else if let statusID = responce["delete"]["status"]["id_str"].string {
                EventBox.post(Event.DestroyStatus.rawValue, sender: statusID)
            } else if responce["delete"]["direct_message"] != nil {
            } else if responce["direct_message"] != nil {
            } else if responce["text"] != nil {
                let status = TwitterStatus(responce)
                EventBox.post(Event.CreateStatus.rawValue, sender: status)
            } else if responce["disconnect"] != nil {
                Static.enableStreaming = false
                Static.connectionStatus = .DISCONNECTED
                EventBox.post(Event.StreamingStatusChanged.rawValue)
                let code = responce["disconnect"]["code"].int ?? 0
                let reason = responce["disconnect"]["reason"].string ?? "Unknown"
                ErrorAlert.show("Streaming disconnect", message: "\(reason) (\(code))")
                if code == 6 {
                    revoked()
                }
            } else {
                NSLog("unknown streaming data: \(responce.debugDescription)")
            }
        }
        let success = {
            (data: NSData) -> Void in
            progress(JSON(data: data))
        }
//        let stallWarningHandler = {
//            (code: String?, message: String?, percentFull: Int?) -> Void in
//            
//            print("code:\(code) message:\(message) percentFull:\(percentFull)")
//        }
//        let failure = {
//            (error: NSError) -> Void in
//            
//            Static.connectionStatus = .DISCONNECTED
//            EventBox.post(Event.StreamingStatusChanged.rawValue)
//            NSLog("connectionStatus: DISCONNECTED")
//            
//            print(error)
//        }
        let completion = { (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            Static.connectionStatus = .DISCONNECTED
            EventBox.post(Event.StreamingStatusChanged.rawValue)
            NSLog("connectionStatus: DISCONNECTED")
            NSLog("completion")
            if let response = response as? NSHTTPURLResponse {
                NSLog("[connectionDidFinishLoading] code:\(response.statusCode) data:\(NSString(data: responseData!, encoding: NSUTF8StringEncoding))")
            }
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
        
        if let account = AccountSettingsStore.get()?.account() {
            Static.streamingRequest = account.credential
                .streaming(NSURL(string: "https://userstream.twitter.com/1.1/user.json")!)
                .progress(success)
                .completion(completion)
                .start()
        }
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
    
    class func revoked() {
        if let settings = AccountSettingsStore.get() {
            let currentUserID = settings.account().userID
            let newAccounts = settings.accounts.filter({ $0.userID != currentUserID })
            if newAccounts.count > 0 {
                let newSettings = AccountSettings(current: 0, accounts: newAccounts)
                AccountSettingsStore.save(newSettings)
            } else {
                AccountSettingsStore.clear()
            }
            EventBox.post(TwitterAuthorizeNotification)
        }
    }
}

extension TwitterAPI.Request {
    
    public func send(success: ((JSON) -> Void)) -> NSURLSessionDataTask {
        return send(success, failure: nil)
    }
    
    public func send(success: (([JSON]) -> Void)) -> NSURLSessionDataTask {
        let s = { (json: JSON) in
            if let array = json.array {
                success(array)
            }
        }
        return send(s, failure: nil)
    }
    
    public func send(success: ((JSON) -> Void)?, failure: ((code: Int?, message: String?, error: NSError?) -> Void)?) -> NSURLSessionDataTask {
        return send({ (responseData, response, error) -> Void in
            let url = self.urlRequest.URL?.absoluteString ?? "-"
            if let error = error {
                if let failure = failure {
                    failure(code: nil, message: nil, error: error)
                } else {
                    ErrorAlert.show("Twitter API Error", message: "url:\(url) error:\(error.localizedDescription)")
                }
            } else if let data = responseData {
                let json = JSON(data: data)
                if let errors = json["errors"].array {
                    let code = errors[0]["code"].int ?? 0
                    let message = errors[0]["message"].string ?? "Unknown"
                    let HTTPResponse = response as? NSHTTPURLResponse
                    let HTTPStatusCode = HTTPResponse?.statusCode ?? 0
                    let error = NSError(domain: NSURLErrorDomain, code: HTTPStatusCode, userInfo: nil)
                    if let failure = failure {
                        failure(code: code, message: message, error: error)
                    } else {
                        ErrorAlert.show("Twitter API Error", message: "\(message)(\(code)) url:\(url) code:\(HTTPStatusCode)")
                    }
                } else {
                    success?(json)
                }
            }
        })
    }
}
