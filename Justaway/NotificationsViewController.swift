//
//  NotificationsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip

class NotificationsViewController: StatusTableViewController {
    
    override func saveCache() {
        if self.adapter.rows.count > 0 {
            let statuses = self.adapter.statuses
            let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
            KeyClip.save("notifications", dictionary: dictionary)
            NSLog("notifications saveCache.")
        }
    }
    
    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Async.background {
            if let cache = KeyClip.load("notifications") as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                    success(statuses: statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success(statuses: [TwitterStatus]())
        }
    }
    
    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Twitter.getMentionTimeline(maxID: maxID, success: success, failure: failure)
    }
    
    override func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Twitter.getMentionTimeline(sinceID: sinceID, maxID: maxID, success: success, failure: failure)
    }
    
    override func sinceID() -> String? {
        for status in self.adapter.statuses {
            if status.type == .Normal {
                return status.statusID
            }
        }
        return nil
    }
    
    override func accept(status: TwitterStatus) -> Bool {
        
        if let event = status.event {
            if event == "quoted_tweet" || event == "favorited_retweet" || event == "retweeted_retweet" {
                return true
            }
        }
        
        if let accountSettings = AccountSettingsStore.get() {
            
            if let actionedBy = status.actionedBy {
                if accountSettings.isMe(actionedBy.userID) {
                    return false
                }
            }
            
            for mention in status.mentions {
                if accountSettings.isMe(mention.userID) {
                    return true
                }
            }
            
            if status.isActioned {
                if accountSettings.isMe(status.user.userID) {
                    return true
                }
            }
        }
        
        return false
    }
}