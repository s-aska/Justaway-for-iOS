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
            KeyClip.save(key, dictionary: dictionary as NSDictionary)
            NSLog("notifications saveCache.")
        }
    }

    override func loadCache(_ success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        adapter.activityMode = true
        Async.background {
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            let key = "mentions:\(account.userID)"
            if let cache = KeyClip.load(key) as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                    success(statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success([TwitterStatus]())

            Async.background(after: 0.4, { () -> Void in
                self.refresh()
            })
        }
    }

    override func loadData(_ maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        Twitter.getMentionTimeline(maxID: maxID, success: success, failure: failure)
    }

    override func loadData(sinceID: String?, maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        Twitter.getMentionTimeline(maxID: maxID, sinceID: sinceID, success: success, failure: failure)
    }

    override func accept(_ status: TwitterStatus) -> Bool {
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
