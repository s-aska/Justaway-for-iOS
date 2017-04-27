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

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return userAdapter.tableView(tableView, heightForFooterInSection: section)
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        tableView.backgroundColor = UIColor.clear
        userAdapter.configureView(tableView)
        userAdapter.didScrollToBottom = {
            if let nextCursor = self.nextCursor {
                self.nextCursor = nil
                self.loadData(nextCursor)
            }
        }
    }

    func configureEvent() {
        _ = EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.tableView.setContentOffset(CGPoint.zero, animated: true)
        })
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userAdapter.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return userAdapter.tableView(tableView, cellForRowAt: indexPath)
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return userAdapter.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        userAdapter.tableView(tableView, didSelectRowAt: indexPath)
    }

    override func refresh() {
        loadData()
    }

    func loadData(_ cursor: String? = nil) {
        let s = { (users: [TwitterUserFull], nextCursor: String?) -> Void in
            self.userAdapter.renderData(self.tableView, users: users, mode: (cursor != nil ? .bottom : .over), handler: {
                self.userAdapter.footerIndicatorView?.stopAnimating()
                if let nextCursor = nextCursor, nextCursor != "0" {
                    self.nextCursor = nextCursor
                }
            })
        }

        let f = { (error: NSError) -> Void in
            self.userAdapter.footerIndicatorView?.stopAnimating()
        }

        if !(self.refreshControl?.isRefreshing ?? false) {
            Async.main {
                self.userAdapter.footerIndicatorView?.startAnimating()
                return
            }
        }

        loadData(cursor ?? "-1", success: s, failure: f)
    }

    func loadData(_ cursor: String, success: @escaping ((_ users: [TwitterUserFull], _ nextCursor: String?) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
}
