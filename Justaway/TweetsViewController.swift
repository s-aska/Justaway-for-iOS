//
//  TweetsViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/28/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Async

class TweetsViewController: UIViewController, TwitterStatusAdapterDelegate {

    // MARK: Properties

    let adapterReplies = TwitterStatusAdapter()
    let adapterNearOriginal = TwitterStatusAdapter()
    let adapterNearRetweet = TwitterStatusAdapter()
    var loaded = false
    var rootStatus: TwitterStatus?

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var tableViewReplies: UITableView!
    @IBOutlet weak var tableViewNearOriginal: UITableView!
    @IBOutlet weak var tableViewNearRetweet: UITableView!

    override var nibName: String {
        return "TweetsViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !loaded {
            loaded = true

            Async.background {
                self.loadData()
            }
        }
    }

    // MARK: - Configuration

    func configureView() {
        guard let rootStatus = rootStatus else {
            hide()
            return
        }

        if rootStatus.actionedBy == nil || rootStatus.type != .Normal {
            segmentedControl.removeSegmentAtIndex(2, animated: false)
            segmentedControl.removeSegmentAtIndex(1, animated: false)
            segmentedControl.insertSegmentWithTitle("Near Tweets", atIndex: 1, animated: false)
        }
        segmentedControl.hidden = false

        indicatorView.activityIndicatorViewStyle = ThemeController.currentTheme.activityIndicatorStyle()
        indicatorView.hidesWhenStopped = true
        indicatorView.startAnimating()
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { [weak self] (n) -> Void in
            guard let `self` = self, rootStatus = self.rootStatus else {
                return
            }
            if self.segmentedControl.selectedSegmentIndex == 0 {
                self.adapterReplies.scrollToTop(self.tableViewReplies)
            } else if self.segmentedControl.selectedSegmentIndex == 1 && rootStatus.actionedBy != nil && rootStatus.type == .Normal {
                self.adapterNearRetweet.scrollToTop(self.tableViewNearRetweet)
            } else {
                self.adapterNearOriginal.scrollToTop(self.tableViewNearOriginal)
            }
        })
    }

    // MARK: Public

    func loadData() {
        guard let rootStatus = rootStatus else {
            return
        }

        let fontSize = CGFloat(GenericSettings.get().fontSize)
        let originalStatus = TwitterStatus(rootStatus, type: .Normal, event: nil, actionedBy: nil, isRoot: true)

        adapterReplies.mainQueue.addOperation(MainBlockOperation({ (op) in
            self.adapterReplies.configureView(nil, tableView: self.tableViewReplies)
            self.adapterReplies.renderData(self.tableViewReplies, statuses: [originalStatus], mode: .BOTTOM, handler: {
                self.indicatorView.stopAnimating()
                self.tableViewReplies.hidden = false
                self.adapterReplies.footerIndicatorView?.startAnimating()
                op.finish()
            })
        }))

        LoadReplies.loadData(adapterReplies, tableView: tableViewReplies, sourceStatus: originalStatus)

        adapterNearOriginal.mainQueue.addOperation(MainBlockOperation({ (op) in
            self.adapterNearOriginal.configureView(self, tableView: self.tableViewNearOriginal)
            let originalRow = self.adapterNearOriginal.createRow(originalStatus, fontSize: fontSize, tableView: self.tableViewNearOriginal)
            self.adapterNearOriginal.rows = [TwitterAdapter.Row(), originalRow, TwitterAdapter.Row()]
            self.tableViewNearOriginal.reloadData()
            op.finish()
        }))

        if rootStatus.actionedBy != nil && rootStatus.type == .Normal {
            adapterNearRetweet.mainQueue.addOperation(MainBlockOperation({ (op) in
                self.adapterNearRetweet.configureView(self, tableView: self.tableViewNearRetweet)
                let retweetRow = self.adapterNearRetweet.createRow(rootStatus, fontSize: fontSize, tableView: self.tableViewNearRetweet)
                self.adapterNearRetweet.rows = [TwitterAdapter.Row(), retweetRow, TwitterAdapter.Row()]
                self.tableViewNearRetweet.reloadData()
                op.finish()
            }))
        }
    }

    // MARK: - TwitterStatusAdapterDelegate

    func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let rootStatus = rootStatus else {
            success(statuses: [])
            return
        }
        if let actionedBy = rootStatus.actionedBy where rootStatus.type == .Normal && segmentedControl.selectedSegmentIndex == 1 {
            Twitter.getUserTimeline(actionedBy.userID, maxID: maxID, sinceID: sinceID, success: success, failure: failure)
        } else {
            Twitter.getUserTimeline(rootStatus.user.userID, maxID: maxID, sinceID: sinceID, success: success, failure: failure)
        }
    }

    // MARK: - Actions

    @IBAction func move(sender: UISegmentedControl) {
        guard let rootStatus = rootStatus else {
            return
        }

        tableViewReplies.hidden = true
        tableViewNearRetweet.hidden = true
        tableViewNearOriginal.hidden = true

        if sender.selectedSegmentIndex == 0 {
            tableViewReplies.hidden = false
        } else if sender.selectedSegmentIndex == 1 && rootStatus.actionedBy != nil && rootStatus.type == .Normal {
            tableViewNearRetweet.hidden = false
        } else {
            tableViewNearOriginal.hidden = false
        }
    }

    @IBAction func left(sender: UIButton) {
        hide()
    }

    func hide() {
        ViewTools.slideOut(self)
    }

    class func show(status: TwitterStatus) {
        let instance = TweetsViewController()
        instance.rootStatus = status
        Async.main {
            ViewTools.slideIn(instance)
        }
    }
}
