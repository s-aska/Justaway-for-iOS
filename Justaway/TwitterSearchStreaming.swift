import UIKit
import Accounts
import EventBox
import KeyClip
import TwitterAPI
import OAuthSwift
import SwiftyJSON
import Async
import Reachability

class TwitterSearchStreaming {

    var request: StreamingRequest?
    let account: Account
    let receiveStatus: (TwitterStatus -> Void)
    let connected: (() -> Void)
    let disconnected: (() -> Void)
    var status = Twitter.ConnectionStatus.DISCONNECTED

    init(account: Account, receiveStatus: (TwitterStatus -> Void), connected: (() -> Void), disconnected: (() -> Void)) {
        self.account = account
        self.receiveStatus = receiveStatus
        self.connected = connected
        self.disconnected = disconnected
    }

    func start(track: String) -> TwitterSearchStreaming {
        NSLog("TwitterSearchStreaming: start")
        request = account.client
            .streaming("https://stream.twitter.com/1.1/statuses/filter.json", parameters: ["track": track])
            .progress(progress)
            .completion(completion)
            .start()
        status = .CONNECTING
        return self
    }

    func stop() {
        NSLog("TwitterSearchStreaming: stop")
        status = .DISCONNECTING
        request?.stop()
    }

    func progress(data: NSData) {
        if self.status != .CONNECTED {
            self.status = .CONNECTED
            Async.main {
                self.connected()
            }
        }
        let responce = JSON(data: data)
        if responce["text"] == nil {
            return
        }
        let sourceUserID = account.userID
        let status = TwitterStatus(responce, connectionID: "")
        let quotedUserID = status.quotedStatus?.user.userID
        let retweetUserID = status.actionedBy != nil && status.type != .Favorite ? status.actionedBy?.userID : nil
        Relationship.check(sourceUserID, targetUserID: status.user.userID, retweetUserID: retweetUserID, quotedUserID: quotedUserID) { (blocking, muting, want_retweets) -> Void in
            if blocking || muting || want_retweets {
                NSLog("skip blocking:\(blocking) muting:\(muting) want_retweets:\(want_retweets) text:\(status.text)")
                return
            }
            Async.main {
                self.receiveStatus(status)
            }
        }
    }

    func completion(responseData: NSData?, response: NSURLResponse?, error: NSError?) {
        status = .DISCONNECTED
        Async.main {
            self.disconnected()
        }
        if let response = response as? NSHTTPURLResponse {
            NSLog("TwitterSearchStreaming [connectionDidFinishLoading] code:\(response.statusCode) data:\(NSString(data: responseData!, encoding: NSUTF8StringEncoding))")
            if response.statusCode == 420 {
                // Rate Limited
                // The client has connected too frequently. For example, an endpoint returns this status if:
                // - A client makes too many login attempts in a short period of time.
                // - Too many copies of an application attempt to authenticate with the same credentials.
                ErrorAlert.show("Streaming API Rate Limited", message: "The client has connected too frequently.")
            }
        }
    }
}
