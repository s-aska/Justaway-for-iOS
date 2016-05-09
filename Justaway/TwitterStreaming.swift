import UIKit
import Accounts
import EventBox
import KeyClip
import TwitterAPI
import OAuthSwift
import SwiftyJSON
import Async
import Reachability

// MARK: - Streaming

extension Twitter {

    struct StreaminStatic {
        private static let connectionQueue = dispatch_queue_create("pw.aska.justaway.twitter.connection", DISPATCH_QUEUE_SERIAL)
        private static var account: Account?
    }

    class func changeMode(mode: StreamingMode) {
        Static.streamingMode = mode
        KeyClip.save("settings.streamingMode", string: mode.rawValue)

        startStreamingIfEnable()

        EventBox.post("changeStreamingMode")
    }

    class func startStreamingIfEnable() {
        if Twitter.enableStreaming {
            startStreamingIfDisconnected()
        }
    }

    class func startStreamingIfDisconnected() {
        Async.customQueue(StreaminStatic.connectionQueue) {
            if Static.connectionStatus == .DISCONNECTED {
                Static.connectionStatus = .CONNECTING
                EventBox.post(Event.StreamingStatusChanged.rawValue)
                NSLog("connectionStatus: CONNECTING")
                Twitter.startStreaming()
            }
        }
    }

    class func startStreaming() {
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

        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        StreaminStatic.account = account
        Static.streamingRequest = account.client
            .streaming("https://userstream.twitter.com/1.1/user.json")
            .progress(Twitter.streamingProgressHandler)
            .completion(Twitter.streamingCompletionHandler)
            .start()
    }

    class func streamingProgressHandler(data: NSData) {
        let responce = JSON(data: data)
        if responce["friends"] != nil {
            NSLog("friends is not null")
            if Static.connectionStatus != .CONNECTED {
                Static.connectionStatus = .CONNECTED
                Static.connectionID = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970.description
                EventBox.post(Event.StreamingStatusChanged.rawValue)
                NSLog("connectionStatus: CONNECTED")
                // UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        } else if let event = responce["event"].string {
            receiveEvent(responce, event: event)
        } else if let statusID = responce["delete"]["status"]["id_str"].string {
            receiveDestroyStatus(statusID)
        } else if let messageID = responce["delete"]["direct_message"]["id_str"].string {
            receiveDestroyMessage(messageID)
        } else if responce["direct_message"] != nil {
            receiveMessage(responce["direct_message"])
        } else if responce["text"] != nil {
            receiveStatus(responce)
        } else if responce["disconnect"] != nil {
            receiveDisconnect(responce)
        } else {
            NSLog("unknown streaming data: \(responce.debugDescription)")
        }
    }

    class func streamingCompletionHandler(responseData: NSData?, response: NSURLResponse?, error: NSError?) {
        Static.connectionStatus = .DISCONNECTED
        EventBox.post(Event.StreamingStatusChanged.rawValue)
        NSLog("connectionStatus: DISCONNECTED")
        NSLog("completion")
        if let response = response as? NSHTTPURLResponse {
            NSLog("[connectionDidFinishLoading] code:\(response.statusCode) data:\(NSString(data: responseData!, encoding: NSUTF8StringEncoding))")
            if response.statusCode == 420 {
                // Rate Limited
                // The client has connected too frequently. For example, an endpoint returns this status if:
                // - A client makes too many login attempts in a short period of time.
                // - Too many copies of an application attempt to authenticate with the same credentials.
                ErrorAlert.show("Streaming API Rate Limited", message: "The client has connected too frequently.")
            }
        }
    }

    class func receiveEvent(responce: JSON, event: String) {
        NSLog("event:\(event)")
        if event == "favorite" {
            let status = TwitterStatus(responce, connectionID: Static.connectionID)
            EventBox.post(Event.CreateStatus.rawValue, sender: status)
            if AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                if (Static.favorites[status.statusID] ?? false) != true {
                    Static.favorites[status.statusID] = true
                    EventBox.post(Event.CreateFavorites.rawValue, sender: status.statusID)
                }
            }
        } else if event == "unfavorite" {
            let status = TwitterStatus(responce, connectionID: Static.connectionID)
            if AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                Static.favorites.removeValueForKey(status.statusID)
                EventBox.post(Event.DestroyFavorites.rawValue, sender: status.statusID)
            }
        } else if event == "quoted_tweet" || event == "favorited_retweet" || event == "retweeted_retweet" {
            let status = TwitterStatus(responce, connectionID: Static.connectionID)
            if event == "favorited_retweet" && AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                NSLog("duplicate?")
            } else {
                EventBox.post(Event.CreateStatus.rawValue, sender: status)
            }
        } else if event == "block" {
            if let account = StreaminStatic.account, targetUserID = responce["target"]["id_str"].string {
                Relationship.block(account, targetUserID: targetUserID)
            }
        } else if event == "unblock" {
            if let account = StreaminStatic.account, targetUserID = responce["target"]["id_str"].string {
                Relationship.unblock(account, targetUserID: targetUserID)
            }
        } else if event == "mute" {
            if let account = StreaminStatic.account, targetUserID = responce["target"]["id_str"].string {
                Relationship.mute(account, targetUserID: targetUserID)
            }
        } else if event == "unmute" {
            if let account = StreaminStatic.account, targetUserID = responce["target"]["id_str"].string {
                Relationship.unmute(account, targetUserID: targetUserID)
            }
        } else if event == "list_member_added",
            let targetUserID = responce["target"]["id_str"].string,
                targetListID = responce["target_object"]["id_str"].string {
            EventBox.post(Twitter.Event.ListMemberAdded.rawValue, sender: ["targetUserID": targetUserID, "targetListID": targetListID])
        } else if event == "list_member_removed",
            let targetUserID = responce["target"]["id_str"].string,
                targetListID = responce["target_object"]["id_str"].string {
                EventBox.post(Twitter.Event.ListMemberRemoved.rawValue, sender: ["targetUserID": targetUserID, "targetListID": targetListID])
        } else if event == "access_revoked" {
            revoked()
        }
    }

    class func receiveStatus(responce: JSON) {
        let sourceUserID = StreaminStatic.account?.userID ?? ""
        let status = TwitterStatus(responce, connectionID: Static.connectionID)
        let quotedUserID = status.quotedStatus?.user.userID
        let retweetUserID = status.actionedBy != nil && status.type != .Favorite ? status.actionedBy?.userID : nil
        Relationship.check(sourceUserID, targetUserID: status.user.userID, retweetUserID: retweetUserID, quotedUserID: quotedUserID) { (blocking, muting, want_retweets) -> Void in
            if blocking || muting || want_retweets {
                NSLog("skip blocking:\(blocking) muting:\(muting) want_retweets:\(want_retweets) text:\(status.text)")
                return
            }
            EventBox.post(Event.CreateStatus.rawValue, sender: status)
        }
    }

    class func receiveDestroyStatus(statusID: String) {
        EventBox.post(Event.DestroyStatus.rawValue, sender: statusID)
    }

    class func receiveMessage(responce: JSON) {
        if let account = StreaminStatic.account {
            let message = TwitterMessage(responce, ownerID: account.userID)
            if let messages = Twitter.messages[account.userID] {
                if !messages.contains({ $0.id == message.id }) {
                    Twitter.messages[account.userID]?.insert(message, atIndex: 0)
                    EventBox.post(Event.CreateMessage.rawValue, sender: message)
                }
            } else {
                Twitter.messages[account.userID] = [message]
                EventBox.post(Event.CreateMessage.rawValue, sender: message)
            }
        }
    }

    class func receiveDestroyMessage(messageID: String) {
        if let account = StreaminStatic.account {
            if let messages = Twitter.messages[account.userID] {
                Twitter.messages[account.userID] = messages.filter({ $0.id != messageID })
            }
        }
        EventBox.post(Event.DestroyMessage.rawValue, sender: messageID)
    }

    class func receiveDisconnect(responce: JSON) {
        Static.connectionStatus = .DISCONNECTED
        EventBox.post(Event.StreamingStatusChanged.rawValue)
        let code = responce["disconnect"]["code"].int ?? 0
        let reason = responce["disconnect"]["reason"].string ?? "Unknown"
        ErrorAlert.show("Streaming disconnect", message: "\(reason) (\(code))")
        if code == 6 {
            revoked()
        }
    }

    class func stopStreamingIFConnected() {
        Async.customQueue(StreaminStatic.connectionQueue) {
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
            EventBox.post(twitterAuthorizeNotification)
        }
    }
}
