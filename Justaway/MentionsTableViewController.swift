//
//  MentionsTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/22/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip
import Async

class MentionsTableViewController: StatusTableViewController {

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            let key = "mentions:\(account.userID)"
            let statuses = self.adapter.statuses
            let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
            KeyClip.save(key, dictionary: dictionary)
            NSLog("notifications saveCache.")
        }
    }

    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        adapter.activityMode = true
        Async.background {
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            let key = "mentions:\(account.userID)"
            if let cache = KeyClip.load(key) as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
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

    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Twitter.getMentionTimeline(maxID: maxID, success: success, failure: failure)
    }

    override func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Twitter.getMentionTimeline(sinceID: sinceID, maxID: maxID, success: success, failure: failure)
    }

    override func accept(status: TwitterStatus) -> Bool {
        if let accountSettings = AccountSettingsStore.get() {
            for mention in status.mentions {
                if accountSettings.isMe(mention.userID) {
                    return true
                }
            }
        }
        return false
    }
}
