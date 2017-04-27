//
//  SearchStatusTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip
import Async

class HomeTimelineTableViewController: StatusTableViewController {

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            let statuses = self.adapter.statuses
            let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
            _ = KeyClip.save("homeTimeline", dictionary: dictionary as NSDictionary)
            NSLog("homeTimeline saveCache.")
        }
    }

    override func loadCache(_ success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        Async.background {
            if let cache = KeyClip.load("homeTimeline") as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                    success(statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success([TwitterStatus]())

            Async.background(after: 0.3, { () -> Void in
                self.loadData(nil)
            })
        }
    }

    override func loadData(_ maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        Twitter.getHomeTimeline(maxID: maxID, success: success, failure: failure)
    }

    override func loadData(sinceID: String?, maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        Twitter.getHomeTimeline(maxID: maxID, sinceID: sinceID, success: success, failure: failure)
    }

    override func accept(_ status: TwitterStatus) -> Bool {
        if status.event != nil {
            return false
        }
        return true
    }
}
