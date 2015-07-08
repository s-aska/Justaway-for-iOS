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
    var scrollCallback: ((scrollView: UIScrollView) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cacheLoaded = true // no cache
        scrollEnd() // contentInset call scrollViewDidScroll, but call scrollEnd
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        scrollCallback?(scrollView: scrollView)
    }
    
    override func saveCache() {
    }
    
    override func loadData(id: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getUserTimeline(userID, maxID: id, success: success, failure: failure)
        }
    }
    
    override func accept(status: TwitterStatus) -> Bool {
        return false
    }
}
