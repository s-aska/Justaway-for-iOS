//
//  AroundViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/15/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwiftyJSON

class AroundViewController: TweetsViewController, TwitterStatusAdapterDelegate {

    var userID: String?
    var statusID: String?
    var rootStatus: TwitterStatus?

    override func configureView() {
        adapter.configureView(self, tableView: tableView)
    }

    // MARK: - TweetsViewController

    override func loadData() {
        guard let rootStatus = rootStatus else {
            return
        }
        let fontSize = CGFloat(GenericSettings.get().fontSize)
        adapter.rows = [TwitterAdapter.Row(), adapter.createRow(rootStatus, fontSize: fontSize, tableView: tableView), TwitterAdapter.Row()]
        tableView.reloadData()
    }

    // MARK: - TwitterStatusAdapterDelegate

    func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let userID = userID else {
            success(statuses: [])
            return
        }
        Twitter.getUserTimeline(userID, maxID: maxID, sinceID: sinceID, success: success, failure: failure)
    }

    // MARK: - Class Methods

    class func show(userID: String, statusID: String, rootStatus: TwitterStatus) {
        let instance = AroundViewController()
        instance.userID = userID
        instance.statusID = statusID
        instance.rootStatus = rootStatus
        ViewTools.slideIn(instance)
    }
}
