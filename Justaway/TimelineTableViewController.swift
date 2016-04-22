//
//  TimelineTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class TimelineTableViewController: UITableViewController {

    let defaultAdapter = TwitterStatusAdapter()
    var adapter: TwitterAdapter {
        return defaultAdapter
    }
    var setup = false

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for c in tableView.visibleCells {
            if let cell = c as? TwitterStatusCell {
                 cell.statusLabel.setAttributes()
            }
        }

    }

    func refresh() {
        assertionFailure("not implements.")
    }

    func saveCache() {
        assertionFailure("not implements.")
    }
}
