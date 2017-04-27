//
//  UserTimelineTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import KeyClip
import Async

class UserTimelineTableViewController: StatusTableViewController {

    var userID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            if let userID = self.userID {
                let key = "user:\(userID)"
                let statuses = self.adapter.statuses
                let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
                KeyClip.save(key, dictionary: dictionary as NSDictionary)
                NSLog("\(key) saveCache.")
            }
        }
    }

    override func loadCache(_ success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = self.userID {
            let key = "user:\(userID)"
            Async.background {
                if let cache = KeyClip.load(key) as NSDictionary? {
                    if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                        success(statuses.map({ TwitterStatus($0) }))
                        return
                    }
                }
                success([TwitterStatus]())

                Async.background(after: 0.5, { () -> Void in
                    self.loadData(nil)
                })
            }
        } else {
            success([])
        }
    }

    override func loadData(_ maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getUserTimeline(userID, maxID: maxID, success: success, failure: failure)
        }
    }

    override func loadData(sinceID: String?, maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getUserTimeline(userID, maxID: maxID, sinceID: sinceID, success: success, failure: failure)
        }
    }

    override func accept(_ status: TwitterStatus) -> Bool {
        return false
    }
}
