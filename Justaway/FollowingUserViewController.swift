//
//  FollowingUserViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

class FollowingUserViewController: UserTableViewController {
    override func loadData(id: String?, success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getFollowingUsers(userID, success: success, failure: failure)
        }
    }
}
