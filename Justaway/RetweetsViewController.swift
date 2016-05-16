//
//  RetweetsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/15/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import Async

class RetweetsViewController: UsersViewController {

    var statusID: String?

    override func loadData(success success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
        if let statusID = statusID {
            Twitter.getRetweeters(statusID, success: success, failure: failure)
        }
    }

    class func show(statusID: String) {
        let instance = RetweetsViewController()
        instance.statusID = statusID
        Async.main {
            ViewTools.slideIn(instance, keepEditor: false)
        }
    }
}
