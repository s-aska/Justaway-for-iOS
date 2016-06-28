//
//  NotificationsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip
import Async

class NotificationsViewController: StatusTableViewController {

    var maxMentionID: String?

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            let key = "notifications:\(account.userID)"
            let statuses = self.adapter.statuses
            let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
            KeyClip.save(key, dictionary: dictionary)
            NSLog("notifications saveCache.")
        }
    }

    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        adapter.activityMode = true
        maxMentionID = nil
        Async.background {
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            let oldKey = "notifications:\(account.userID)"
            KeyClip.delete(oldKey)
            let key = "notifications-v2:\(account.userID)"
            if let cache = KeyClip.load(key) as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] where statuses.count > 0 {
                    success(statuses: statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success(statuses: [TwitterStatus]())

            Async.background(after: 0.4, block: { () -> Void in
                self.loadData(nil)
            })
        }
    }

    override func refresh() {
        maxMentionID = nil
        loadData(nil)
    }

    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        if account.exToken.isEmpty {
            Twitter.getMentionTimeline(maxID: maxID, success: success, failure: failure)
        } else {
            let activitySuccess = { (statuses: [TwitterStatus], maxMentionID: String?) -> Void in
                if let maxMentionID = maxMentionID {
                    self.maxMentionID = maxMentionID
                }
                success(statuses: statuses)
            }
            Twitter.getActivity(maxID: maxID, maxMentionID: maxMentionID, success: activitySuccess, failure: failure)
        }
    }

    override func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        if account.exToken.isEmpty {
            Twitter.getMentionTimeline(sinceID: sinceID, maxID: maxID, success: success, failure: failure)
        } else {
            let activitySuccess = { (statuses: [TwitterStatus], maxMentionID: String?) -> Void in
                if let maxMentionID = maxMentionID {
                    self.maxMentionID = maxMentionID
                }
                success(statuses: statuses)
            }
            Twitter.getActivity(sinceID: sinceID, maxID: maxID, maxMentionID: maxMentionID, success: activitySuccess, failure: failure)
        }
    }

    override func accept(status: TwitterStatus) -> Bool {

        if let event = status.event {
            if let accountSettings = AccountSettingsStore.get() {
                if let actionedBy = status.actionedBy {
                    if accountSettings.isMe(actionedBy.userID) {
                        return false
                    }
                } else {
                    if accountSettings.isMe(status.user.userID) {
                        return false
                    }
                }
            }
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
