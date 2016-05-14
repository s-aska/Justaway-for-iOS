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

class Relationship {

    struct Static {
        static var users = [String: Data]()
        private static let queue = NSOperationQueue().serial()
    }

    struct Data {
        var friends = [String: Bool]()
        var followers = [String: Bool]()
        var blocks = [String: Bool]()
        var mutes = [String: Bool]()
        var noRetweets = [String: Bool]()
    }

    class func check(sourceUserID: String, targetUserID: String, retweetUserID: String?, quotedUserID: String?, callback: ((blocking: Bool, muting: Bool, wantRetweets: Bool) -> Void)) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            guard let data = Static.users[sourceUserID] else {
                op.finish()
                callback(blocking: false, muting: false, wantRetweets: false)
                return
            }

            var blocking = data.blocks[targetUserID] ?? false
            var muting = data.mutes[targetUserID] ?? false
            var wantRetweets = false

            if let retweetUserID = retweetUserID {
                wantRetweets = data.noRetweets[retweetUserID] ?? false
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
            callback(blocking: blocking, muting: muting, wantRetweets: wantRetweets)
        }))
    }

    class func checkUser(sourceUserID: String, targetUserID: String, callback: ((relationshop: TwitterRelationship) -> Void)) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            guard let data = Static.users[sourceUserID] else {
                op.finish()
                callback(relationshop: TwitterRelationship(following: false, followedBy: false, blocking: false, muting: false, wantRetweets: false))
                return
            }

            let following = data.friends[targetUserID] ?? false
            let followedBy = data.followers[targetUserID] ?? false
            let blocking = data.blocks[targetUserID] ?? false
            let muting = data.mutes[targetUserID] ?? false
            let noRetweets = data.noRetweets[targetUserID] ?? false

            op.finish()
            callback(relationshop: TwitterRelationship(following: following, followedBy: followedBy, blocking: blocking, muting: muting, wantRetweets: !noRetweets))
        }))
    }

    class func follow(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.friends[targetUserID] = true
            op.finish()
        }))
    }

    class func unfollow(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.friends.removeValueForKey(targetUserID)
            op.finish()
        }))
    }

    class func followed(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.followers[targetUserID] = true
            op.finish()
        }))
    }

    class func block(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.blocks[targetUserID] = true
            op.finish()
        }))
    }

    class func unblock(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.blocks.removeValueForKey(targetUserID)
            op.finish()
        }))
    }

    class func mute(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.mutes[targetUserID] = true
            op.finish()
        }))
    }

    class func unmute(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.mutes.removeValueForKey(targetUserID)
            op.finish()
        }))
    }

    class func turnOffRetweets(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.noRetweets[targetUserID] = true
            op.finish()
        }))
    }

    class func turnOnRetweets(account: Account, targetUserID: String) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            Static.users[account.userID]?.noRetweets.removeValueForKey(targetUserID)
            op.finish()
        }))
    }

    class func setup(account: Account) {
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

    class func load(account: Account) {
        loadFriends(account)
        loadFollowers(account)
        loadMutes(account)
        loadNoRetweets(account)
        loadBlocks(account)
    }

    class func loadFriends(account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-friends-\(account.userID)"
            let now = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                createdAt = cache["createdAt"] as? NSNumber,
                ids = cache["ids"] as? [String]
                where (now - createdAt.doubleValue) < 600 {
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
                KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/friends/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadFollowers(account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-followers-\(account.userID)"
            let now = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                createdAt = cache["createdAt"] as? NSNumber,
                ids = cache["ids"] as? [String]
                where (now - createdAt.doubleValue) < 600 {
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
                KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/followers/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadMutes(account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-mutes-\(account.userID)"
            let now = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                createdAt = cache["createdAt"] as? NSNumber,
                ids = cache["ids"] as? [String]
                where (now - createdAt.doubleValue) < 600 {
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
                KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/mutes/users/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadNoRetweets(account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-noRetweets-\(account.userID)"
            let now = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                createdAt = cache["createdAt"] as? NSNumber,
                ids = cache["ids"] as? [String]
                where (now - createdAt.doubleValue) < 600 {
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
                KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/friendships/no_retweets/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSONArray(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }

    class func loadBlocks(account: Account) {
        Static.queue.addOperation(AsyncBlockOperation({ (op) in
            let cacheKey = "relationship-blocks-\(account.userID)"
            let now = NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970
            if let cache = KeyClip.load(cacheKey) as NSDictionary?,
                createdAt = cache["createdAt"] as? NSNumber,
                ids = cache["ids"] as? [String]
                where (now - createdAt.doubleValue) < 600 {
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
                KeyClip.save(cacheKey, dictionary: ["ids": ids, "createdAt": Int(NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970)])
            }
            account.client
                .get("https://api.twitter.com/1.1/blocks/ids.json", parameters: ["stringify_ids": "true"])
                .responseJSON(success, failure: { (code, message, error) in
                    op.finish()
                })
        }))
    }
}
