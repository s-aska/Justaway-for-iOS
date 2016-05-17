//
//  UsersViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/15/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Async
import EventBox

class UsersViewController: UIViewController {


    // MARK: Properties

    @IBOutlet weak var tableView: UITableView!

    let adapter = TwitterUserAdapter()
    var loaded = false

    override var nibName: String {
        return "UsersViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if loaded == false {
            loaded = true
            loadData()
        }
    }

    // MARK: - Configuration

    func configureView() {
        adapter.configureView(tableView)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.tableView.setContentOffset(CGPoint(x: 0, y: -self.tableView.contentInset.top), animated: true)
        })
    }

    // MARK: - Private

    func loadData() {
        let fontSize = CGFloat(GenericSettings.get().fontSize)

        let s = { (users: [TwitterUserFull]) -> Void in
            self.adapter.rows = users.map({ self.adapter.createRow($0, fontSize: fontSize, tableView: self.tableView) })
            self.tableView.reloadData()
            self.adapter.footerIndicatorView?.stopAnimating()
        }

        let f = { (error: NSError) -> Void in
            self.adapter.footerIndicatorView?.stopAnimating()
        }

        Async.main {
            self.adapter.footerIndicatorView?.startAnimating()
        }

        loadData(success: s, failure: f)
    }

    func loadData(success success: ((users: [TwitterUserFull]) -> Void), failure: ((error: NSError) -> Void)) {
    }

    // MARK: - Action

    @IBAction func left(sender: UIButton) {
        hide()
    }

    // MARK: - Public

    func hide() {
        ViewTools.slideOut(self)
    }
}
