//
//  Relationship.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/15/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import SwiftyJSON
import KeyClip
import Async

class Relationship {

    struct Static {
        static var users = [String: Data]()
        fileprivate static let queue = OperationQueue().serial()
    }

    struct Data {
        var friends = [String: Bool]()
        var followers = [String: Bool]()
        var blocks = [String: Bool]()
        var mutes = [String: Bool]()
        var noRetweets = [String: Bool]()
    }

    class func check(_ sourceUserID: String, targetUserID: String, retweetUserID: String?, quotedUserID: String?, callback: @escaping ((_ blocking: Bool, _ muting: Bool, _ noRetweets: Bool) -> Void)) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            guard let data = Static.users[sourceUserID] else {
                op.finish()
                callback(false, false, false)
                return
            }

            var blocking = data.blocks[targetUserID] ?? false
            var muting = data.mutes[targetUserID] ?? false
            var noRetweets = false

            if let retweetUserID = retweetUserID {
                noRetweets = data.noRetweets[retweetUserID] ?? false
            }

            if let quotedUserID = quotedUserID {
                if !blocking {
                    blocking = data.blocks[quotedUserID] ?? false
                }
                if !muting {
                    muting = data.mutes[quotedUserID] ?? false
                }
            }
            op.finish()
            Async.main {
                callback(blocking, muting, noRetweets)
            }
        }))
    }

    class func checkUser(_ sourceUserID: String, targetUserID: String, callback: @escaping ((_ relationshop: TwitterRelationship) -> Void)) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            guard let data = Static.users[sourceUserID] else {
                op.finish()
                Async.main {
                    callback(TwitterRelationship(following: false, followedBy: false, blocking: false, muting: false, wantRetweets: false))
                }
                return
            }

            let following = data.friends[targetUserID] ?? false
            let followedBy = data.followers[targetUserID] ?? false
            let blocking = data.blocks[targetUserID] ?? false
            let muting = data.mutes[targetUserID] ?? false
            let noRetweets = data.noRetweets[targetUserID] ?? false

            op.finish()
            Async.main {
                callback(TwitterRelationship(following: following, followedBy: followedBy, blocking: blocking, muting: muting, wantRetweets: !noRetweets))
            }
        }))
    }

    class func follow(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.friends[targetUserID] = true
            op.finish()
        }))
    }

    class func unfollow(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.friends.removeValue(forKey: targetUserID)
            op.finish()
        }))
    }

    class func followed(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.followers[targetUserID] = true
            op.finish()
        }))
    }

    class func block(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.blocks[targetUserID] = true
            op.finish()
        }))
    }

    class func unblock(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.blocks.removeValue(forKey: targetUserID)
            op.finish()
        }))
    }

    class func mute(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.mutes[targetUserID] = true
            op.finish()
        }))
    }

    class func unmute(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.mutes.removeValue(forKey: targetUserID)
            op.finish()
        }))
    }

    class func turnOffRetweets(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.noRetweets[targetUserID] = true
            op.finish()
        }))
    }

    class func turnOnRetweets(_ account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.noRetweets.removeValue(forKey: targetUserID)
            op.finish()
        }))
    }

    class func setup(_ account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            if Static.users[account.userID] != nil {
                op.finish()
                return
            }
            Static.users[account.userID] = Data()
            op.finish()
            load(account)
        }))
    }

    class func load(_ account: Account) {
        loadFriends(account)
        loadFollowers(account)
        loadMutes(account)
        loadNoRetweets(account)
        loadBlocks(account)
    }

    class func loadFriends(_ account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-friends-\(account.userID)"
            let now = Date(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                let createdAt = cache["createdAt"] as? NSNumber,
                let ids = cache["ids"] as? [String], (now - createdAt.doubleValue) < 600 {
                NSLog("[Relationship] load cache user:\(account.screenName) friends: \(ids.count) delta:\(now - createdAt.doubleValue)")
                for id in ids {
                    Static.users[account.userID]?.friends[id] = true
                }
                op.finish()
                return
            }
            let success = { (json: JSON) -> Void in
                guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                    op.finish()
                    return
                }
                NSLog("[Relationship] load user:\(account.screenName) friends: \(ids.count)")
                for id in ids {
                    Static.users[account.userID]?.friends[id] = true
                }
                op.finish()
                _ = KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/friends/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadFollowers(_ account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-followers-\(account.userID)"
            let now = Date(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                let createdAt = cache["createdAt"] as? NSNumber,
                let ids = cache["ids"] as? [String], (now - createdAt.doubleValue) < 600 {
                NSLog("[Relationship] load cache user:\(account.screenName) followers: \(ids.count) delta:\(now - createdAt.doubleValue)")
                for id in ids {
                    Static.users[account.userID]?.followers[id] = true
                }
                op.finish()
                return
            }
            let success = { (json: JSON) -> Void in
                guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                    op.finish()
                    return
                }
                NSLog("[Relationship] load user:\(account.screenName) followers: \(ids.count)")
                for id in ids {
                    Static.users[account.userID]?.followers[id] = true
                }
                op.finish()
                _ = KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/followers/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadMutes(_ account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-mutes-\(account.userID)"
            let now = Date(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                let createdAt = cache["createdAt"] as? NSNumber,
                let ids = cache["ids"] as? [String], (now - createdAt.doubleValue) < 600 {
                NSLog("[Relationship] load cache user:\(account.screenName) mutes: \(ids.count) delta:\(now - createdAt.doubleValue)")
                for id in ids {
                    Static.users[account.userID]?.mutes[id] = true
                }
                op.finish()
                return
            }
            let success = { (json: JSON) -> Void in
                guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                    op.finish()
                    return
                }
                NSLog("[Relationship] load user:\(account.screenName) mutes: \(ids.count)")
                for id in ids {
                    Static.users[account.userID]?.mutes[id] = true
                }
                op.finish()
                _ = KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/mutes/users/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadNoRetweets(_ account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-noRetweets-\(account.userID)"
            let now = Date(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                let createdAt = cache["createdAt"] as? NSNumber,
                let ids = cache["ids"] as? [String], (now - createdAt.doubleValue) < 600 {
                NSLog("[Relationship] load cache user:\(account.screenName) noRetweets: \(ids.count) delta:\(now - createdAt.doubleValue)")
                for id in ids {
                    Static.users[account.userID]?.noRetweets[id] = true
                }
                op.finish()
                return
            }
            let success = { (array: [JSON]) -> Void in
                let ids = array.map({ $0.string ?? "" }).filter({ !$0.isEmpty })
                NSLog("[Relationship] load user:\(account.screenName) noRetweets: \(ids.count)")
                for id in ids {
                    Static.users[account.userID]?.noRetweets[id] = true
                }
                op.finish()
                _ = KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/friendships/no_retweets/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSONArray(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadBlocks(_ account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-blocks-\(account.userID)"
            let now = Date(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                let createdAt = cache["createdAt"] as? NSNumber,
                let ids = cache["ids"] as? [String], (now - createdAt.doubleValue) < 600 {
                NSLog("[Relationship] load cache user:\(account.screenName) blocks: \(ids.count) delta:\(now - createdAt.doubleValue)")
                for id in ids {
                    Static.users[account.userID]?.blocks[id] = true
                }
                op.finish()
                return
            }
            let success = { (json: JSON) -> Void in
                guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                    op.finish()
                    return
                }
                NSLog("[Relationship] load user:\(account.screenName) blocks: \(ids.count)")
                for id in ids {
                    Static.users[account.userID]?.blocks[id] = true
                }
                op.finish()
                _ = KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/blocks/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }
}
