//
//  UserTimelineViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import KeyClip

class UserTimelineTableViewController: StatusTableViewController {
    
    var userID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cacheLoaded = true // no cache
        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }
    
    override func saveCache() {
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
