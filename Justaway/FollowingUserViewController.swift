//
//  FollowingUserViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

class FollowingUserViewController: UserTableViewController {
    override func loadData(cursor: String, success: ((users: [TwitterUserFull], nextCursor: String?) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
            Twitter.getFollowingUsers(userID, cursor: cursor, success: success, failure: failure)
        }
    }
}
