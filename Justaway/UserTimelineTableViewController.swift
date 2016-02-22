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
                KeyClip.save(key, dictionary: dictionary)
                NSLog("\(key) saveCache.")
            }
        }
    }

    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = self.userID {
            let key = "user:\(userID)"
            Async.background {
                if let cache = KeyClip.load(key) as NSDictionary? {
                    if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                        success(statuses: statuses.map({ TwitterStatus($0) }))
                        return
                    }
                }
                success(statuses: [TwitterStatus]())

                Async.background(after: 0.5, block: { () -> Void in
                    self.loadData(nil)
                })
            }
        } else {
            success(statuses: [])
        }
    }

    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getUserTimeline(userID, maxID: maxID, success: success, failure: failure)
        }
    }

    override func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getUserTimeline(userID, sinceID: sinceID, maxID: maxID, success: success, failure: failure)
        }
    }

    override func accept(status: TwitterStatus) -> Bool {
        return false
    }
}
