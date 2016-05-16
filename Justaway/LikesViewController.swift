//
//  LikesViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/15/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import Async

class LikesViewController: UsersViewController {

    var status: TwitterStatus?

    override func loadData(success success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
        if let status = status {
            Twitter.getFavoriters(status, success: success, failure: failure)
        }
    }

    class func show(status: TwitterStatus) {
        let instance = LikesViewController()
        instance.status = status
        Async.main {
            ViewTools.slideIn(instance, keepEditor: false)
        }
    }
}
