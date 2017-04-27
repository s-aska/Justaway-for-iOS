import UIKit
import Accounts
import EventBox
import KeyClip
import TwitterAPI
import OAuthSwift
import SwiftyJSON
import Async
import Reachability

let twitterAuthorizeNotification = Notification.Name.init(rawValue: "TwitterAuthorizeNotification")

class Twitter {

    // MARK: - Types

    enum ConnectionStatus {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }

    enum StreamingMode: String {
        case Manual = "Manual"
        case AutoOnWiFi = "AutoOnWiFi"
        case AutoAlways = "AutoAlways"
    }

    enum Event: String {
        case CreateStatus = "CreateStatus"
        case CreateFavorites = "CreateFavorites"
        case DestroyFavorites = "DestroyFavorites"
        case CreateRetweet = "CreateRetweet"
        case DestroyRetweet = "DestroyRetweet"
        case DestroyStatus = "DestroyStatus"
        case CreateMessage = "CreateMessage"
        case DestroyMessage = "DestroyMessage"
        case StreamingStatusChanged = "StreamingStatusChanged"
        case ListMemberAdded = "ListMemberAdded"
        case ListMemberRemoved = "ListMemberRemoved"

        func Name() -> Notification.Name {
            return Notification.Name.init(rawValue: self.rawValue)
        }
    }

    struct Static {
        static var reachability: Reachability? // keep memory
        static var streamingMode = StreamingMode.Manual
        static var onWiFi = false
        static var connectionStatus: ConnectionStatus = .disconnected
        static var connectionID: String = Date(timeIntervalSinceNow: 0).timeIntervalSince1970.description
        static var streamingRequest: StreamingRequest?
        static var favorites = [String: Bool]()
        static var retweets = [String: String]()
        static var messages = [String: [TwitterMessage]]()
        static var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
        fileprivate static let favoritesQueue = DispatchQueue(label: "pw.aska.justaway.twitter.favorites", attributes: [])
        fileprivate static let retweetsQueue = DispatchQueue(label: "pw.aska.justaway.twitter.retweets", attributes: [])
        fileprivate static let messagesSemaphore = DispatchSemaphore(value: 1)
    }

    class var connectionStatus: ConnectionStatus { return Static.connectionStatus }
    class var streamingMode: StreamingMode { return Static.streamingMode }
    class var messages: [String: [TwitterMessage]] {
        get {
            Static.messagesSemaphore.wait(timeout: DispatchTime.distantFuture)
            let messages = Static.messages
            Static.messagesSemaphore.signal()
            return messages
        }
        set {
            _ = Static.messagesSemaphore.wait(timeout: DispatchTime.distantFuture)
            Static.messages = newValue
            Static.messagesSemaphore.signal()
        }
    }

    class var enableStreaming: Bool {
        switch Static.streamingMode {
        case .Manual:
            return false
        case .AutoAlways:
            return true
        case .AutoOnWiFi:
            return Static.onWiFi
        }
    }

    // MARK: - Class Methods

    class func setup() {
        guard let r = Reachability.init() else {
            print("Unable to create Reachability")
            return
        }
        Static.reachability = r

        Static.reachability?.whenReachable = { reachability in
            NSLog("whenReachable")
            Async.main {
                if reachability.isReachableViaWiFi {
                    NSLog("Reachable via WiFi")
                    Static.onWiFi = true
                } else {
                    NSLog("Reachable via Cellular")
                    Static.onWiFi = false
                }
            }
            Async.main(after: 2) {
                Twitter.startStreamingIfEnable()
            }
            return
        }

        Static.reachability?.whenUnreachable = { reachability in
            Async.main {
                NSLog("whenUnreachable")
                Static.onWiFi = false
            }
        }

        do {
            try Static.reachability?.startNotifier()
        } catch {
            print("Unable to start notifier")
        }

        if let streamingModeString: String = KeyClip.load("settings.streamingMode") {
            if let streamingMode = StreamingMode(rawValue: streamingModeString) {
                Static.streamingMode = streamingMode
            } else {
                _ = KeyClip.delete("settings.streamingMode")
            }
        }
    }

    class func addOAuthAccount() {
        let failure: ((OAuthSwiftError) -> Void) = {
            error in

            if error._code == 401 {
                ErrorAlert.show("Twitter auth failure", message: error.localizedDescription)
            } else if error._code == 429 {
                ErrorAlert.show("Twitter auth failure", message: "API Limit")
            } else {
                ErrorAlert.show("Twitter auth failure", message: error.localizedDescription)
                EventBox.post(twitterAuthorizeNotification)
            }
        }

        let oauthswift = OAuth1Swift(
            consumerKey:    twitterConsumerKey,
            consumerSecret: twitterConsumerSecret,
            requestTokenUrl: "https://api.twitter.com/oauth/request_token",
            authorizeUrl:    "https://api.twitter.com/oauth/authorize",
            accessTokenUrl:  "https://api.twitter.com/oauth/access_token"
        )
        oauthswift.authorizeURLHandler = SafariOAuthURLHandler()
        oauthswift.authorize(withCallbackURL: "justaway://success", success: {
            credential, response, parameters in

            let client = OAuthClient(
                consumerKey: twitterConsumerKey,
                consumerSecret: twitterConsumerSecret,
                accessToken: credential.oauthToken,
                accessTokenSecret: credential.oauthTokenSecret)

            client.get("https://api.twitter.com/1.1/account/verify_credentials.json")
                .responseJSON { (json: JSON) -> Void in
                    let user = TwitterUserFull(json)
                    let exToken = AccountSettingsStore.get()?.find(user.userID)?.exToken ?? ""
                    let account = Account(
                        client: client,
                        userID: user.userID,
                        screenName: user.screenName,
                        name: user.name,
                        profileImageURL: user.profileImageURL,
                        profileBannerURL: user.profileBannerURL,
                        exToken: exToken)
                    Twitter.refreshAccounts([account])
                }
        }, failure: failure)
    }

    class func addACAccount(_ silent: Bool) {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)

        // Prompt the user for permission to their twitter account stored in the phone's settings
        accountStore.requestAccessToAccounts(with: accountType, options: nil) {
            granted, error in

            if granted {
                let twitterAccounts = accountStore.accounts(with: accountType) as? [ACAccount] ?? []

                if twitterAccounts.count == 0 {
                    if !silent {
                        MessageAlert.show("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                    }
                    EventBox.post(twitterAuthorizeNotification)
                } else {
                    Twitter.refreshAccounts(
                        twitterAccounts.map({ (account: ACAccount) in
                            let userID = account.value(forKeyPath: "properties.user_id") as? String ?? ""
                            if let account = AccountSettingsStore.get()?.find(userID), account.isOAuth {
                                return account
                            }
                            let exToken = AccountSettingsStore.get()?.find(userID)?.exToken ?? ""
                            return Account(
                                client: AccountClient(account: account),
                                userID: userID,
                                screenName: account.username,
                                name: account.username,
                                profileImageURL: nil,
                                profileBannerURL: nil,
                                exToken: exToken)
                        })
                    )
                }
            } else {
                if !silent {
                    MessageAlert.show("Error", message: "Twitter requires you to authorize Justaway for iOS to use your account.")
                }
                EventBox.post(twitterAuthorizeNotification)
            }
        }
    }

    class func refreshAccounts(_ newAccounts: [Account]) {
        let accountSettings: AccountSettings

        if let storeAccountSettings = AccountSettingsStore.get() {
            accountSettings = storeAccountSettings.merge(newAccounts)
        } else if newAccounts.count > 0 {
            accountSettings = AccountSettings(current: 0, accounts: newAccounts)
        } else {
            return
        }

        let userIDs = accountSettings.accounts.map({ $0.userID }).joined(separator: ",")

        let success: (([JSON]) -> Void) = { (rows) in

            let users = rows.map { TwitterUserFull($0) }

            // Save Device
            AccountSettingsStore.save(accountSettings.update(users))

            EventBox.post(twitterAuthorizeNotification)
        }

        let parameters = ["user_id": userIDs]
        accountSettings.account()?.client
            .get("https://api.twitter.com/1.1/users/lookup.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in

                AccountSettingsStore.save(accountSettings)

                EventBox.post(twitterAuthorizeNotification)
            })
    }

    class func client() -> Client? {
        let client = AccountSettingsStore.get()?.account()?.client
        if let c = client as? AccountClient {
            NSLog("debugDescription:\(c.debugDescription)")
        }
        return client
    }

    class func getHomeTimeline(maxID: String? = nil, sinceID: String? = nil, success: @escaping ([TwitterStatus]) -> Void, failure: @escaping (NSError) -> Void) {
        var parameters = [String: String]()
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let success = { (array: [JSON]) -> Void in
            let statuses = array.map({ TwitterStatus($0) })
            success(statuses)
            if maxID == nil {
                let dictionary = ["statuses": statuses.map({ $0.dictionaryValue })]
                if KeyClip.save("homeTimeline", dictionary: dictionary as NSDictionary) {
                    NSLog("homeTimeline cache success.")
                }
            }
        }
        client()?
            .get("https://api.twitter.com/1.1/statuses/home_timeline.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getStatuses(_ statusIDs: [String], success: @escaping ([TwitterStatus]) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["id": statusIDs.joined(separator: ",")]
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
        client()?
            .get("https://api.twitter.com/1.1/statuses/lookup.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getUsers(_ userIDs: [String], success: @escaping ([TwitterUser]) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["user_id": userIDs.joined(separator: ",")]
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterUser($0) }))
        }
        client()?
            .get("https://api.twitter.com/1.1/users/lookup.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getUsers(_ userIDs: [String], success: @escaping ([TwitterUserFull]) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["user_id": userIDs.joined(separator: ",")]
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterUserFull($0) }))
        }
        client()?
            .get("https://api.twitter.com/1.1/users/lookup.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getUsers(_ keyword: String, page: Int = 1, success: @escaping ([TwitterUserFull]) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["q": keyword, "count": "200", "page": String(page), "include_entities": "false"]
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterUserFull($0) }))
        }
        client()?
            .get("https://api.twitter.com/1.1/users/search.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getRetweeters(_ statusID: String, success: @escaping ([TwitterUserFull]) -> Void, failure: @escaping (NSError) -> Void) {
        let retweetersSuccess = { (json: JSON) -> Void in
            guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                success([])
                return
            }
            Twitter.getUsers(ids, success: success, failure: failure)
        }
        let parameters = ["id": statusID, "count": "100", "stringify_ids": "true"]
        client()?
            .get("https://api.twitter.com/1.1/statuses/retweeters/ids.json", parameters: parameters)
            .responseJSON(retweetersSuccess, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getUserTimeline(_ userID: String, maxID: String? = nil, sinceID: String? = nil, success: @escaping ([TwitterStatus]) -> Void, failure: @escaping (NSError) -> Void) {
        var parameters = ["user_id": userID]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
        client()?
            .get("https://api.twitter.com/1.1/statuses/user_timeline.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getMentionTimeline(maxID: String? = nil, sinceID: String? = nil, success: @escaping ([TwitterStatus]) -> Void, failure: @escaping (NSError) -> Void) {
        var parameters: [String: String] = [:]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let success = { (array: [JSON]) -> Void in

            let statuses = array.map({ TwitterStatus($0) })

            success(statuses)

            if maxID == nil {
                let dictionary = ["statuses": statuses.map({ $0.dictionaryValue })]
                if KeyClip.save("mentionTimeline", dictionary: dictionary as NSDictionary) {
                    NSLog("mentionTimeline cache success.")
                }
            }
        }
        client()?
            .get("https://api.twitter.com/1.1/statuses/mentions_timeline.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getSearchTweets(_ keyword: String, maxID: String? = nil, sinceID: String? = nil, excludeRetweets: Bool = true, resultType: String = "recent", success: @escaping ([TwitterStatus], [String: JSON]) -> Void, failure: @escaping (NSError) -> Void) {
        var parameters: [String: String] = ["count": "200", "q": keyword + (excludeRetweets ? " exclude:retweets" : ""), "result_type": resultType]
        if let maxID = maxID {
            parameters["max_id"] = maxID
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
        }
        let success = { (json: JSON) -> Void in
            if let statuses = json["statuses"].array,
                let search_metadata = json["search_metadata"].dictionary {
                    success(statuses.map({ TwitterStatus($0) }), search_metadata)
            }
        }
        NSLog("parameters:\(parameters)")
        client()?
            .get("https://api.twitter.com/1.1/search/tweets.json", parameters: parameters)
            .responseJSON(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getListsStatuses(_ listID: String, maxID: String? = nil, sinceID: String? = nil, success: @escaping ([TwitterStatus]) -> Void, failure: @escaping (NSError) -> Void) {
        var parameters = ["list_id": listID]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
        client()?.get("https://api.twitter.com/1.1/lists/statuses.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getFavorites(_ userID: String, maxID: String? = nil, sinceID: String? = nil, success: @escaping ([TwitterStatus]) -> Void, failure: @escaping (NSError) -> Void) {
        var parameters = ["user_id": userID]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterStatus($0) }))
        }
        client()?.get("https://api.twitter.com/1.1/favorites/list.json", parameters: parameters)
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getDirectMessages(_ success: @escaping ([TwitterMessage]) -> Void) {
        guard let account = AccountSettingsStore.get()?.account() else {
            success([])
            return
        }

        let client = account.client
        let parameters = ["count": "200", "full_text": "true"]
        let successReceived = { (array: [JSON]) -> Void in
            let reveivedArray = array
            let successSent = { (array: [JSON]) -> Void in
                var idMap = [String: Bool]()
                success((reveivedArray + array)
                    .map({ TwitterMessage($0, ownerID: account.userID) })
                    .filter({ (message: TwitterMessage) -> Bool in
                        if idMap[message.id] != nil {
                            return false
                        } else {
                            idMap[message.id] = true
                            return true
                        }
                    })
                    .sorted(by: {
                        return $0.0.createdAt.date.timeIntervalSince1970 > $0.1.createdAt.date.timeIntervalSince1970
                    }))
            }
            client.get("https://api.twitter.com/1.1/direct_messages/sent.json", parameters: parameters)
                .responseJSONArray(successSent)
        }
        client.get("https://api.twitter.com/1.1/direct_messages.json", parameters: parameters)
            .responseJSONArray(successReceived)
    }

    class func getFriendships(_ targetID: String, success: @escaping (TwitterRelationship) -> Void) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["source_id": account.userID, "target_id": targetID]
        let success = { (json: JSON) -> Void in
            if let source: JSON = json["relationship"]["source"] {
                let relationship = TwitterRelationship(source)
                success(relationship)
            }
        }
        client()?.get("https://api.twitter.com/1.1/friendships/show.json", parameters: parameters)
            .responseJSON(success)
    }

    class func getFollowingUsers(_ userID: String, cursor: String = "-1", success: @escaping (_ users: [TwitterUserFull], _ nextCursor: String?) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["user_id": userID, "cursor": cursor, "count": "200"]
        let success = { (json: JSON) -> Void in
            if let users = json["users"].array {
                success(users.map({ TwitterUserFull($0) }), json["next_cursor_str"].string)
            }
        }
        client()?
            .get("https://api.twitter.com/1.1/friends/list.json", parameters: parameters)
            .responseJSON(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getFollowerUsers(_ userID: String, cursor: String = "-1", success: @escaping (_ users: [TwitterUserFull], _ nextCursor: String?) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["user_id": userID, "cursor": cursor, "count": "200"]
        let success = { (json: JSON) -> Void in
            if let users = json["users"].array {
                success(users.map({ TwitterUserFull($0) }), json["next_cursor_str"].string)
            }
        }
        client()?
            .get("https://api.twitter.com/1.1/followers/list.json", parameters: parameters)
            .responseJSON(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getListsMemberOf(_ userID: String, success: @escaping ([TwitterList]) -> Void, failure: @escaping (NSError) -> Void) {
        let parameters = ["user_id": userID, "count": "200"]
        let success = { (json: JSON) -> Void in
            if let lists = json["lists"].array {
                success(lists.map({ TwitterList($0) }))
            }
        }
        client()?
            .get("https://api.twitter.com/1.1/lists/memberships.json", parameters: parameters)
            .responseJSON(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getSavedSearches(_ success: @escaping ([String]) -> Void, failure: @escaping (NSError) -> Void) {
        let success = { (array: [JSON]) -> Void in
            success(array.map({ $0["query"].string ?? "" }))
        }
        client()?
            .get("https://api.twitter.com/1.1/saved_searches/list.json", parameters: [:])
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func getLists(_ success: @escaping ([TwitterList]) -> Void, failure: @escaping (NSError) -> Void) {
        let success = { (array: [JSON]) -> Void in
            success(array.map({ TwitterList($0) }))
        }
        client()?
            .get("https://api.twitter.com/1.1/lists/list.json", parameters: [:])
            .responseJSONArray(success, failure: { (code, message, error) -> Void in
                failure(error)
            })
    }

    class func statusUpdate(_ status: String, inReplyToStatusID: String?, images: [Data], mediaIds: [String]) {
        if images.count == 0 {
            return statusUpdate(status, inReplyToStatusID: inReplyToStatusID, mediaIds: mediaIds)
        }
        var images = images
        let image = images.remove(at: 0)
        Async.background { () -> Void in
            client()?
                .postMedia(image)
                .responseJSON { (json: JSON) -> Void in
                    var mediaIds = mediaIds
                    if let media_id = json["media_id_string"].string {
                        mediaIds.append(media_id)
                    }
                    self.statusUpdate(status, inReplyToStatusID: inReplyToStatusID, images: images, mediaIds: mediaIds)
                }
        }
    }

    class func statusUpdate(_ status: String, inReplyToStatusID: String?, mediaIds: [String]) {
        var parameters = [String: String]()
        parameters["status"] = status
        if let inReplyToStatusID = inReplyToStatusID {
            parameters["in_reply_to_status_id"] = inReplyToStatusID
        }
        if mediaIds.count > 0 {
            parameters["media_ids"] = mediaIds.joined(separator: ",")
        }
        client()?.post("https://api.twitter.com/1.1/statuses/update.json", parameters: parameters).responseJSONWithError(nil, failure: nil)
    }

    class func postDirectMessage(_ text: String, userID: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["text": text, "user_id": userID]
        account.client.post("https://api.twitter.com/1.1/direct_messages/new.json", parameters: parameters).responseJSONWithError({ (json) in
            let message = TwitterMessage(json, ownerID: account.userID)
            if Twitter.messages[account.userID] != nil {
                Twitter.messages[account.userID]?.insert(message, at: 0)
            } else {
                Twitter.messages[account.userID] = [message]
            }
            EventBox.post(Event.CreateMessage.Name(), sender: message)
        }, failure: nil)
    }
}

// MARK: - Virtual

extension Twitter {

    class func reply(_ status: TwitterStatus) {
        if let account = AccountSettingsStore.get()?.account() {
            let prefix = "@\(status.user.screenName) "
            var users = status.mentions
            if let actionedBy = status.actionedBy {
                users.append(actionedBy)
            }
            let mentions = users.filter({ $0.userID != status.user.userID && account.userID != $0.userID }).map({ "@\($0.screenName) " }).joined(separator: "")
            let range = NSRange.init(location: prefix.characters.count, length: mentions.characters.count)
            EditorViewController.show(prefix + mentions, range: range, inReplyToStatus: status)
        }
    }

    class func quoteURL(_ status: TwitterStatus) {
        EditorViewController.show(" \(status.statusURL)", range: NSRange(location: 0, length: 0), inReplyToStatus: status)
    }

}

// MARK: - REST API

extension Twitter {

    class func isFavorite(_ statusID: String, handler: @escaping (Bool) -> Void) {
        Async.custom(queue: Static.favoritesQueue) {
            handler(Static.favorites[statusID] == true)
        }
    }

    class func toggleFavorite(_ statusID: String) {
        Async.custom(queue: Static.favoritesQueue) {
            if Static.favorites[statusID] == true {
                Twitter.destroyFavorite(statusID)
            } else {
                Async.background {
                    Twitter.createFavorite(statusID)
                }
            }
        }
    }

    class func createFavorite(_ statusID: String) {
        Async.custom(queue: Static.favoritesQueue) {
            if Static.favorites[statusID] == true {
                ErrorAlert.show("Like failure", message: "already like.")
                return
            }
            Static.favorites[statusID] = true
            EventBox.post(Event.CreateFavorites.Name(), sender: statusID as AnyObject)
            let parameters = ["id": statusID]
            client()?
                .post("https://api.twitter.com/1.1/favorites/create.json", parameters: parameters)
                .responseJSONWithError({ (json) -> Void in

                    }, failure: { (code, message, error) -> Void in
                        if code == 139 {
                            ErrorAlert.show("Like failure", message: "already like.")
                        } else {
                            Async.custom(queue: Static.favoritesQueue) {
                                Static.favorites.removeValue(forKey: statusID)
                                EventBox.post(Event.DestroyFavorites.Name(), sender: statusID as AnyObject)
                            }
                            ErrorAlert.show("Like failure", message: message ?? error.localizedDescription)
                        }
                })
        }
    }

    class func destroyFavorite(_ statusID: String) {
        Async.custom(queue: Static.favoritesQueue) {
            if Static.favorites[statusID] == nil {
                ErrorAlert.show("Unlike failure", message: "missing like.")
                return
            }
            Static.favorites.removeValue(forKey: statusID)
            EventBox.post(Event.DestroyFavorites.Name(), sender: statusID as AnyObject)
            let parameters = ["id": statusID]
            client()?
                .post("https://api.twitter.com/1.1/favorites/destroy.json", parameters: parameters)
                .responseJSONWithError({ (json: JSON) -> Void in

                }, failure: { (code, message, error) -> Void in
                    if code == 34 {
                        ErrorAlert.show("Unlike failure", message: "missing like.")
                    } else {
                        Async.custom(queue: Static.favoritesQueue) {
                            Static.favorites[statusID] = true
                            EventBox.post(Event.CreateFavorites.Name(), sender: statusID as AnyObject)
                        }
                        ErrorAlert.show("Unlike failure", message: message ?? error.localizedDescription)
                    }
            })
        }
    }

    class func isRetweet(_ statusID: String, handler: @escaping (String?) -> Void) {
        Async.custom(queue: Static.retweetsQueue) {
            handler(Static.retweets[statusID])
        }
    }

    class func createRetweet(_ statusID: String) {
        Async.custom(queue: Static.retweetsQueue) {
            if Static.retweets[statusID] != nil {
                ErrorAlert.show("Retweet failure", message: "already retweets.")
                return
            }
            Static.retweets[statusID] = "0"
            EventBox.post(Event.CreateRetweet.Name(), sender: statusID as AnyObject)
            client()?
                .post("https://api.twitter.com/1.1/statuses/retweet/\(statusID).json")
                .responseJSONWithError({ (json: JSON) -> Void in
                    Async.custom(queue: Static.retweetsQueue) {
                        if let id = json["id_str"].string {
                            Static.retweets[statusID] = id
                        }
                    }
                    return
                }, failure: { (code, message, error) -> Void in
                    if code == 34 {
                        ErrorAlert.show("Retweet failure", message: "already retweets.")
                    } else {
                        Async.custom(queue: Static.retweetsQueue) {
                            Static.retweets.removeValue(forKey: statusID)
                            EventBox.post(Event.DestroyRetweet.Name(), sender: statusID as AnyObject)
                        }
                        ErrorAlert.show("Retweet failure", message: message ?? error.localizedDescription)
                    }
                })
        }
    }

    class func destroyRetweet(_ statusID: String, retweetedStatusID: String) {
        Async.custom(queue: Static.retweetsQueue) {
            if Static.retweets[statusID] == nil {
                ErrorAlert.show("Unod Retweet failure", message: "missing retweets.")
                return
            }
            Static.retweets.removeValue(forKey: statusID)
            EventBox.post(Event.DestroyRetweet.Name(), sender: statusID as AnyObject)
            client()?
                .post("https://api.twitter.com/1.1/statuses/destroy/\(retweetedStatusID).json", parameters: [:])
                .responseJSONWithError({ (json: JSON) -> Void in
                }, failure: { (code, message, error) -> Void in
                        if code == 34 {
                            ErrorAlert.show("Undo Retweet failure", message: "missing retweets.")
                        } else {
                            Async.custom(queue: Static.retweetsQueue) {
                                Static.retweets[statusID] = retweetedStatusID
                                EventBox.post(Event.CreateRetweet.Name(), sender: statusID as AnyObject)
                            }
                            ErrorAlert.show("Undo Retweet failure", message: message ?? error.localizedDescription)
                        }
                })
        }
    }

    class func destroyStatus(_ account: Account, statusID: String) {
        account
            .client
            .post("https://api.twitter.com/1.1/statuses/destroy/\(statusID).json")
            .responseJSONWithError({ (json: JSON) -> Void in
                EventBox.post(Event.DestroyStatus.Name(), sender: statusID as AnyObject)
            }, failure: { (code, message, error) -> Void in
                ErrorAlert.show("Undo Tweet failure code:\(code)", message: message ?? error.localizedDescription)
            })
    }

    class func destroyMessage(_ account: Account, messageID: String) {
        account
            .client
            .post("https://api.twitter.com/1.1/direct_messages/destroy.json", parameters: ["id": messageID])
            .responseJSONWithError({ (json: JSON) -> Void in
                if let messages = Twitter.messages[account.userID] {
                    Twitter.messages[account.userID] = messages.filter({ $0.id != messageID })
                }
                EventBox.post(Event.DestroyMessage.Name(), sender: messageID as AnyObject)
                }, failure: nil)
    }

    class func follow(_ userID: String, success: (() -> Void)? = nil) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID]
        account.client
            .post("https://api.twitter.com/1.1/friendships/create.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.follow(account, targetUserID: userID)
                if let success = success {
                    success()
                } else {
                    ErrorAlert.show("Follow success")
                }
            })
    }

    class func unfollow(_ userID: String, success: (() -> Void)? = nil) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID]
        account.client
            .post("https://api.twitter.com/1.1/friendships/destroy.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.unfollow(account, targetUserID: userID)
                if let success = success {
                    success()
                } else {
                    ErrorAlert.show("Unfollow success")
                }
            })
    }

    class func turnOnNotification(_ userID: String) {
        let parameters = ["user_id": userID, "device": "true"]
        client()?.post("https://api.twitter.com/1.1/friendships/update.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                ErrorAlert.show("Turn on notification success")
            })
    }

    class func turnOffNotification(_ userID: String) {
        let parameters = ["user_id": userID, "device": "false"]
        client()?
            .post("https://api.twitter.com/1.1/friendships/update.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                ErrorAlert.show("Turn off notification success")
            })
    }

    class func turnOnRetweets(_ userID: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID, "retweets": "true"]
        account.client
            .post("https://api.twitter.com/1.1/friendships/update.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.turnOnRetweets(account, targetUserID: userID)
                ErrorAlert.show("Turn on retweets success")
            })
    }

    class func turnOffRetweets(_ userID: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID, "retweets": "false"]
        account.client
            .post("https://api.twitter.com/1.1/friendships/update.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.turnOffRetweets(account, targetUserID: userID)
                ErrorAlert.show("Turn off retweets success")
            })
    }

    class func mute(_ userID: String) { //
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID]
        account.client
            .post("https://api.twitter.com/1.1/mutes/users/create.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.mute(account, targetUserID: userID)
                ErrorAlert.show("Mute success")
            })
    }

    class func unmute(_ userID: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID]
        account.client
            .post("https://api.twitter.com/1.1/mutes/users/destroy.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.unmute(account, targetUserID: userID)
                ErrorAlert.show("Unmute success")
            })
    }

    class func block(_ userID: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID]
        account.client
            .post("https://api.twitter.com/1.1/blocks/create.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.block(account, targetUserID: userID)
                ErrorAlert.show("Block success")
            })
    }

    class func unblock(_ userID: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let parameters = ["user_id": userID]
        account.client
            .post("https://api.twitter.com/1.1/blocks/destroy.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                Relationship.unblock(account, targetUserID: userID)
                ErrorAlert.show("Unblock success")
            })
    }

    class func reportSpam(_ userID: String) {
        let parameters = ["user_id": userID]
        client()?
            .post("https://api.twitter.com/1.1/users/report_spam.json", parameters: parameters)
            .responseJSON({ (json: JSON) -> Void in
                ErrorAlert.show("Report success")
            })
    }
}

extension TwitterAPI.Request {

    public func responseJSON(_ success: @escaping ((JSON) -> Void)) {
        return responseJSONWithError(success, failure: nil)
    }

    public func responseJSON(_ success: @escaping ((JSON) -> Void), failure: ((_ code: Int?, _ message: String?, _ error: NSError) -> Void)?) {
        return responseJSONWithError(success, failure: failure)
    }

    public func responseJSONArray(_ success: @escaping (([JSON]) -> Void)) {
        let s = { (json: JSON) in
            if let array = json.array {
                success(array)
            }
        }
        responseJSONWithError(s, failure: nil)
    }

    public func responseJSONArray(_ success: @escaping (([JSON]) -> Void), failure: ((_ code: Int?, _ message: String?, _ error: NSError) -> Void)?) {
        let s = { (json: JSON) in
            if let array = json.array {
                success(array)
            }
        }
        responseJSONWithError(s, failure: failure)
    }

    public func responseJSONWithError(_ success: ((JSON) -> Void)?, failure: ((_ code: Int?, _ message: String?, _ error: NSError) -> Void)?) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        let url = self.originalRequest.url?.absoluteString ?? "-"
        let account = AccountSettingsStore.get()?.accounts.filter({ $0.client.serialize == self.originalClient.serialize }).first
        response { (responseData, response, error) -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let error = error {
                if let failure = failure {
                    failure(nil, nil, error)
                } else {
                    ErrorAlert.show("Twitter API Error", message: "url:\(url) error:\(error.localizedDescription)")
                }
            } else if let data = responseData {
                let json = JSON(data: data)
                if json.error != nil {
                    let HTTPResponse = response
                    let HTTPStatusCode = HTTPResponse?.statusCode ?? 0
                    let error = NSError.init(domain: NSURLErrorDomain, code: HTTPStatusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Twitter API Error\nURL:\(url)\nHTTP StatusCode:\(HTTPStatusCode)",
                        NSLocalizedRecoverySuggestionErrorKey: "-"
                    ])
                    if let failure = failure {
                        failure(nil, nil, error)
                    } else {
                        ErrorAlert.show("Twitter API Error", message: error.localizedDescription)
                    }
                } else if let errors = json["errors"].array {
                    let code = errors[0]["code"].int ?? 0
                    let message = errors[0]["message"].string ?? "Unknown"
                    let HTTPResponse = response
                    let HTTPStatusCode = HTTPResponse?.statusCode ?? 0
                    var localizedDescription = "Twitter API Error\nErrorMessage:\(message)\nErrorCode:\(code)\nURL:\(url)\nHTTP StatusCode:\(HTTPStatusCode)"
                    var recoverySuggestion = "-"
                    if HTTPStatusCode == 401 && code == 89 {
                        localizedDescription = "Was revoked access"
                        if let account = account {
                            localizedDescription += " @\(account.screenName)"
                        }
                        if (account?.client as? OAuthClient) != nil {
                            recoverySuggestion = "1. Open the menu (upper left).\n2. Open the Accounts.\n3. Tap the [Add]\n4. Choose via Justaway for iOS\n5. Authorize app."
                        } else {
                            recoverySuggestion = "1. Tap the Home button.\n2. Open the [Settings].\n3. Open the [Twitter].\n4. Delete all account.\n5. Add all account.\n6. Open the Justaway."
                        }
                    }
                    let error = NSError.init(domain: NSURLErrorDomain, code: HTTPStatusCode, userInfo: [
                        NSLocalizedDescriptionKey: localizedDescription,
                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
                    ])
                    if let failure = failure {
                        failure(code, message, error)
                    } else {
                        ErrorAlert.show("Twitter API Error", message: error.localizedDescription)
                    }
                } else {
                    success?(json)
                }
            }

        }
    }
}
