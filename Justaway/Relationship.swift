//
//  Relationship.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/15/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import Async
import SwiftyJSON

class Relationship {

    struct Static {
        static var users = [String: Data]()
        private static let queue = dispatch_queue_create("pw.aska.justaway.relationship", DISPATCH_QUEUE_SERIAL)
    }

    struct Data {
        var blocks = [String: Bool]()
        var mutes = [String: Bool]()
        var noRetweets = [String: Bool]()
    }

    class func check(sourceUserID: String, targetUserID: String, retweetUserID: String?, quotedUserID: String?, callback: ((blocking: Bool, muting: Bool, want_retweets: Bool) -> Void)) {
        dispatch_sync(Static.queue) {
            guard let data = Static.users[sourceUserID] else {
                callback(blocking: false, muting: false, want_retweets: false)
                return
            }

            var blocking = data.blocks[targetUserID] ?? false
            var muting = data.mutes[targetUserID] ?? false
            var want_retweets = false

            if let retweetUserID = retweetUserID {
                want_retweets = data.noRetweets[retweetUserID] ?? false
            }

            if let quotedUserID = quotedUserID {
                if !blocking {
                    blocking = data.blocks[quotedUserID] ?? false
                }
                if !muting {
                    muting = data.mutes[quotedUserID] ?? false
                }
            }

            Async.background {
                callback(blocking: blocking, muting: muting, want_retweets: want_retweets)
            }
        }
    }

    class func block(account: Account, targetUserID: String) {
        dispatch_sync(Static.queue) {
            Static.users[account.userID]?.blocks[targetUserID] = true
        }
    }

    class func unblock(account: Account, targetUserID: String) {
        dispatch_sync(Static.queue) {
            Static.users[account.userID]?.blocks[targetUserID] = false
        }
    }

    class func mute(account: Account, targetUserID: String) {
        dispatch_sync(Static.queue) {
            Static.users[account.userID]?.mutes[targetUserID] = true
        }
    }

    class func unmute(account: Account, targetUserID: String) {
        dispatch_sync(Static.queue) {
            Static.users[account.userID]?.mutes[targetUserID] = false
        }
    }

    class func turnOffRetweets(account: Account, targetUserID: String) {
        dispatch_sync(Static.queue) {
            Static.users[account.userID]?.noRetweets[targetUserID] = true
        }
    }

    class func turnOnRetweets(account: Account, targetUserID: String) {
        dispatch_sync(Static.queue) {
            Static.users[account.userID]?.noRetweets[targetUserID] = false
        }
    }

    class func setup(account: Account) {
        dispatch_sync(Static.queue) {
            if Static.users[account.userID] == nil {
                Async.background {
                    load(account)
                }
            }
        }
    }

    class func load(account: Account) {
        Static.users[account.userID] = Data()

        let successBlocks = { (json: JSON) -> Void in
            guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                return
            }
            NSLog("[Relationship] load user:\(account.screenName) blocks: \(ids.count)")
            dispatch_sync(Static.queue) {
                for id in ids {
                    Static.users[account.userID]?.blocks[id] = true
                }
            }
        }

        let successMutes = { (json: JSON) -> Void in
            guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                return
            }
            NSLog("[Relationship] load user:\(account.screenName) mutes: \(ids.count)")
            dispatch_sync(Static.queue) {
                for id in ids {
                    Static.users[account.userID]?.mutes[id] = true
                }
            }
        }

        let successNoRetweets = { (array: [JSON]) -> Void in
            let ids = array.map({ $0.string ?? "" }).filter({ !$0.isEmpty })
            NSLog("[Relationship] load user:\(account.screenName) noRetweets: \(ids.count)")
            dispatch_sync(Static.queue) {
                for id in ids {
                    Static.users[account.userID]?.noRetweets[id] = true
                }
            }
        }

        account.client
            .get("https://api.twitter.com/1.1/mutes/users/ids.json", parameters: ["stringify_ids": "true"])
            .responseJSON(successMutes)

        account.client
            .get("https://api.twitter.com/1.1/friendships/no_retweets/ids.json", parameters: ["stringify_ids": "true"])
            .responseJSONArray(successNoRetweets)

        account.client
            .get("https://api.twitter.com/1.1/blocks/ids.json", parameters: ["stringify_ids": "true"])
            .responseJSON(successBlocks)
    }
}
