//
//  TimelineTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class TimelineTableViewController: UITableViewController {

    let adapter = TwitterStatusAdapter()
    var setup = false

    func refresh() {
        assertionFailure("not implements.")
    }

    func saveCache() {
        assertionFailure("not implements.")
    }
}
