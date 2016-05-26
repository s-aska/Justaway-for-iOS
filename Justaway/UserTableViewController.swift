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
    var nextCursor: String?

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
        tableView.backgroundColor = UIColor.clearColor()
        userAdapter.configureView(tableView)
        userAdapter.didScrollToBottom = {
            if let nextCursor = self.nextCursor {
                self.nextCursor = nil
                self.loadData(nextCursor)
            }
        }
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
        loadData()
    }

    func loadData(cursor: String? = nil) {
        let s = { (users: [TwitterUserFull], nextCursor: String?) -> Void in
            self.userAdapter.renderData(self.tableView, users: users, mode: (cursor != nil ? .BOTTOM : .OVER), handler: {
                self.userAdapter.footerIndicatorView?.stopAnimating()
                if let nextCursor = nextCursor where nextCursor != "0" {
                    self.nextCursor = nextCursor
                }
            })
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

        loadData(cursor ?? "-1", success: s, failure: f)
    }

    func loadData(cursor: String, success: ((users: [TwitterUserFull], nextCursor: String?) -> Void), failure: ((error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
}
