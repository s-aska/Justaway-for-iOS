//
//  FollowerUserViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

class FollowerUserViewController: UserTableViewController {
    override func loadData(maxID: String?, success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getFollowerUsers(userID, success: success, failure: failure)
        }
    }
}
