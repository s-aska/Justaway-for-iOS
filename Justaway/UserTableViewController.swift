//
//  UserViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Async

class UserTableViewController: TimelineTableViewController {

    // MARK: Properties

    let userAdapter = TwitterUserAdapter()

    var userID: String?

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return userAdapter.tableView(tableView, heightForFooterInSection: section)
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return userAdapter.tableView(tableView, viewForFooterInSection: section)
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        userAdapter.configureView(tableView)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.tableView.setContentOffset(CGPoint.zero, animated: true)
        })
    }

    // MARK: - UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userAdapter.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return userAdapter.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return userAdapter.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        userAdapter.tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }

    override func refresh() {
        loadData(nil)
    }

    func loadData(maxID: Int64?) {
        let fontSize = CGFloat(GenericSettings.get().fontSize)

        let s = { (users: [TwitterUserFull]) -> Void in
            self.userAdapter.rows = users.map({ self.userAdapter.createRow($0, fontSize: fontSize, tableView: self.tableView) })
            self.tableView.reloadData()
            self.userAdapter.footerIndicatorView?.stopAnimating()
        }

        let f = { (error: NSError) -> Void in
            self.userAdapter.footerIndicatorView?.stopAnimating()
        }

        if !(self.refreshControl?.refreshing ?? false) {
            Async.main {
                self.userAdapter.footerIndicatorView?.startAnimating()
                return
            }
        }

        loadData(maxID?.stringValue, success: s, failure: f)
    }

    func loadData(maxID: String?, success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
}
