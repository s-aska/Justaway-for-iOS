//
//  HomeTimelineViewController.swift
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
            KeyClip.save("homeTimeline", dictionary: dictionary)
            NSLog("homeTimeline saveCache.")
        }
    }
    
    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Async.background {
            if let cache = KeyClip.load("homeTimeline") as NSDictionary? {
                if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                    success(statuses: statuses.map({ TwitterStatus($0) }))
                    return
                }
            }
            success(statuses: [TwitterStatus]())
            
            Async.background(after: 0.3, block: { () -> Void in
                self.loadData(nil)
            })
        }
    }
    
    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Twitter.getHomeTimeline(maxID: maxID, success: success, failure: failure)
    }
    
    override func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        Twitter.getHomeTimeline(sinceID: sinceID, maxID: maxID, success: success, failure: failure)
    }
    
    override func accept(status: TwitterStatus) -> Bool {
        if status.event != nil {
            return false
        }
        return true
    }
}
