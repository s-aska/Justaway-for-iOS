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

    override func loadData(success: @escaping ((_ users: [TwitterUserFull]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let statusID = statusID {
            Twitter.getRetweeters(statusID, success: success, failure: failure)
        }
    }

    class func show(_ statusID: String) {
        let instance = RetweetsViewController()
        instance.statusID = statusID
        Async.main {
            ViewTools.slideIn(instance, keepEditor: false)
        }
    }
}
