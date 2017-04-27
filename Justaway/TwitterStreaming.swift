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
        fileprivate static let connectionQueue = DispatchQueue(label: "pw.aska.justaway.twitter.connection", attributes: [])
        fileprivate static var account: Account?
    }

    class func changeMode(_ mode: StreamingMode) {
        Static.streamingMode = mode
        _ = KeyClip.save("settings.streamingMode", string: mode.rawValue)

        startStreamingIfEnable()

        EventBox.post(eventChangeStreamingMode)
    }

    class func startStreamingIfEnable() {
        if Twitter.enableStreaming {
            startStreamingIfDisconnected()
        }
    }

    class func startStreamingIfDisconnected() {
        Async.custom(queue: StreaminStatic.connectionQueue) {
            if Static.connectionStatus == .disconnected {
                Static.connectionStatus = .connecting
                EventBox.post(Event.StreamingStatusChanged.Name())
                NSLog("connectionStatus: CONNECTING")
                Twitter.startStreaming()
            }
        }
    }

    class func startStreaming() {
        if Static.backgroundTaskIdentifier == UIBackgroundTaskInvalid {
            NSLog("backgroundTaskIdentifier: beginBackgroundTask")
            Static.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
                NSLog("backgroundTaskIdentifier: Expiration")
                if Static.backgroundTaskIdentifier != UIBackgroundTaskInvalid {
                    NSLog("backgroundTaskIdentifier: endBackgroundTask")
                    self.stopStreamingIFConnected()
                    UIApplication.shared.endBackgroundTask(Static.backgroundTaskIdentifier)
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

    class func streamingProgressHandler(_ data: Data) {
        let responce = JSON(data: data)
        if responce["friends"] != nil {
            NSLog("friends is not null")
            if Static.connectionStatus != .connected {
                Static.connectionStatus = .connected
                Static.connectionID = Date(timeIntervalSinceNow: 0).timeIntervalSince1970.description
                EventBox.post(Event.StreamingStatusChanged.Name())
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

    class func streamingCompletionHandler(_ responseData: Data?, response: URLResponse?, error: NSError?) {
        Static.connectionStatus = .disconnected
        EventBox.post(Event.StreamingStatusChanged.Name())
        NSLog("connectionStatus: DISCONNECTED")
        NSLog("completion")
        if let response = response as? HTTPURLResponse {
            NSLog("[connectionDidFinishLoading] code:\(response.statusCode) data:\(NSString(data: responseData!, encoding: String.Encoding.utf8.rawValue))")
            if response.statusCode == 420 {
                // Rate Limited
                // The client has connected too frequently. For example, an endpoint returns this status if:
                // - A client makes too many login attempts in a short period of time.
                // - Too many copies of an application attempt to authenticate with the same credentials.
                ErrorAlert.show("Streaming API Rate Limited", message: "The client has connected too frequently.")
            }
        }
    }

    class func receiveEvent(_ responce: JSON, event: String) {
        NSLog("event:\(event)")
        if event == "favorite" {
            let status = TwitterStatus(responce, connectionID: Static.connectionID)
            EventBox.post(Event.CreateStatus.Name(), sender: status)
            if AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                if (Static.favorites[status.statusID] ?? false) != true {
                    Static.favorites[status.statusID] = true
                    EventBox.post(Event.CreateFavorites.Name(), sender: status.statusID as AnyObject)
                }
            }
        } else if event == "unfavorite" {
            let status = TwitterStatus(responce, connectionID: Static.connectionID)
            if AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                Static.favorites.removeValue(forKey: status.statusID)
                EventBox.post(Event.DestroyFavorites.Name(), sender: status.statusID as AnyObject)
            }
        } else if event == "quoted_tweet" || event == "favorited_retweet" || event == "retweeted_retweet" {
            let status = TwitterStatus(responce, connectionID: Static.connectionID)
            if event == "favorited_retweet" && AccountSettingsStore.isCurrent(status.actionedBy?.userID ?? "") {
                NSLog("duplicate?")
            } else {
                EventBox.post(Event.CreateStatus.Name(), sender: status)
            }
        } else if event == "block" {
            if let account = StreaminStatic.account, let targetUserID = responce["target"]["id_str"].string {
                Relationship.block(account, targetUserID: targetUserID)
            }
        } else if event == "unblock" {
            if let account = StreaminStatic.account, let targetUserID = responce["target"]["id_str"].string {
                Relationship.unblock(account, targetUserID: targetUserID)
            }
        } else if event == "mute" {
            if let account = StreaminStatic.account, let targetUserID = responce["target"]["id_str"].string {
                Relationship.mute(account, targetUserID: targetUserID)
            }
        } else if event == "unmute" {
            if let account = StreaminStatic.account, let targetUserID = responce["target"]["id_str"].string {
                Relationship.unmute(account, targetUserID: targetUserID)
            }
        } else if event == "list_member_added",
            let targetUserID = responce["target"]["id_str"].string,
                let targetListID = responce["target_object"]["id_str"].string {
            EventBox.post(Twitter.Event.ListMemberAdded.Name(), sender: ["targetUserID": targetUserID, "targetListID": targetListID] as AnyObject)
        } else if event == "list_member_removed",
            let targetUserID = responce["target"]["id_str"].string,
                let targetListID = responce["target_object"]["id_str"].string {
                EventBox.post(Twitter.Event.ListMemberRemoved.Name(), sender: ["targetUserID": targetUserID, "targetListID": targetListID] as AnyObject)
        } else if event == "access_revoked" {
            revoked()
        }
    }

    class func receiveStatus(_ responce: JSON) {
        let sourceUserID = StreaminStatic.account?.userID ?? ""
        let status = TwitterStatus(responce, connectionID: Static.connectionID)
        let quotedUserID = status.quotedStatus?.user.userID
        let retweetUserID = status.actionedBy != nil && status.type != .favorite ? status.actionedBy?.userID : nil
        Relationship.check(sourceUserID, targetUserID: status.user.userID, retweetUserID: retweetUserID, quotedUserID: quotedUserID) { (blocking, muting, noRetweets) -> Void in
            if blocking || muting || noRetweets {
                // NSLog("skip blocking:\(blocking) muting:\(muting) noRetweets:\(noRetweets) text:\(status.text)")
                return
            }
            EventBox.post(Event.CreateStatus.Name(), sender: status)
        }
    }

    class func receiveDestroyStatus(_ statusID: String) {
        EventBox.post(Event.DestroyStatus.Name(), sender: statusID as AnyObject)
    }

    class func receiveMessage(_ responce: JSON) {
        if let account = StreaminStatic.account {
            let message = TwitterMessage(responce, ownerID: account.userID)
            if let messages = Twitter.messages[account.userID] {
                if !messages.contains(where: { $0.id == message.id }) {
                    Twitter.messages[account.userID]?.insert(message, at: 0)
                    EventBox.post(Event.CreateMessage.Name(), sender: message)
                }
            } else {
                Twitter.messages[account.userID] = [message]
                EventBox.post(Event.CreateMessage.Name(), sender: message)
            }
        }
    }

    class func receiveDestroyMessage(_ messageID: String) {
        if let account = StreaminStatic.account {
            if let messages = Twitter.messages[account.userID] {
                Twitter.messages[account.userID] = messages.filter({ $0.id != messageID })
            }
        }
        EventBox.post(Event.DestroyMessage.Name(), sender: messageID as AnyObject)
    }

    class func receiveDisconnect(_ responce: JSON) {
        Static.connectionStatus = .disconnected
        EventBox.post(Event.StreamingStatusChanged.Name())
        let code = responce["disconnect"]["code"].int ?? 0
        let reason = responce["disconnect"]["reason"].string ?? "Unknown"
        ErrorAlert.show("Streaming disconnect", message: "\(reason) (\(code))")
        if code == 6 {
            revoked()
        }
    }

    class func stopStreamingIFConnected() {
        Async.custom(queue: StreaminStatic.connectionQueue) {
            if Static.connectionStatus == .connected {
                Static.connectionStatus = .disconnected
                EventBox.post(Event.StreamingStatusChanged.Name())
                NSLog("connectionStatus: DISCONNECTED")
                Twitter.stopStreaming()
            }
        }
    }

    class func stopStreaming() {
        Static.streamingRequest?.stop()
    }

    class func revoked() {
        if let settings = AccountSettingsStore.get(), let account = settings.account() {
            let currentUserID = account.userID
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
