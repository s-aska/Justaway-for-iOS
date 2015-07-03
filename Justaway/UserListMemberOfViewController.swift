//
//  UserListMemberOfViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class UserListMemberOfViewController: UserListTableViewController {
    override func loadData(id: String?, success: ((userLists: [TwitterUserList]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = userID {
             Twitter.getListsMemberOf(userID, success: success, failure: failure)
        }
    }
}
