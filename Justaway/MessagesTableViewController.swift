//
//  MessagesTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/16/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwiftyJSON
import KeyClip
import EventBox
import Async

class MessagesTableViewController: TimelineTableViewController {

    let messageAdapter = TwitterMessageAdapter()
    override var adapter: TwitterMessageAdapter {
        return messageAdapter
    }

    var cacheLoaded = false

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
        if !cacheLoaded {
            cacheLoaded = true
            loadCache()
        }
        // adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        self.tableView.backgroundColor = UIColor.clearColor()

        adapter.configureView(tableView)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(TimelineTableViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.adapter.scrollToTop(self.tableView)
        })
        // TODO: copy paste
        EventBox.onBackgroundThread(self, name: eventFontSizeApplied) { (n) -> Void in
            if let fontSize = n.userInfo?["fontSize"] as? NSNumber {
                let newNows = self.adapter.rows.map({ (row) -> TwitterStatusAdapter.Row in
                    if let message = row.message {
                        return self.adapter.createRow(message, fontSize: CGFloat(fontSize.floatValue), tableView: self.tableView)
                    } else {
                        return row
                    }
                })

                let op = MainBlockOperation { (op) -> Void in
                    if var firstCell = self.tableView.visibleCells.first {
                        var offset = self.tableView.contentOffset.y - firstCell.frame.origin.y + self.tableView.contentInset.top
                        var firstPath: NSIndexPath

                        // セルが半分以上隠れているている場合、2番目の表示セルを基準にする
                        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                            if indexPathsForVisibleRows.count > 1 && offset > (firstCell.frame.size.height / 2) {
                                firstPath = indexPathsForVisibleRows[1]
                                firstCell = self.tableView.cellForRowAtIndexPath(firstPath)!
                                offset = self.tableView.contentOffset.y - firstCell.frame.origin.y + self.tableView.contentInset.top
                            } else {
                                firstPath = indexPathsForVisibleRows.first!
                            }

                            self.adapter.rows = newNows

                            self.tableView.reloadData()
                            self.tableView.scrollToRowAtIndexPath(firstPath, atScrollPosition: .Top, animated: false)
                            self.tableView.setContentOffset(CGPoint.init(x: 0, y: self.tableView.contentOffset.y + offset), animated: false)
                        }
                    }
                    op.finish()
                }
                self.adapter.mainQueue.addOperation(op)
            }
        }
        configureCreateMessageEvent()
        configureDestroyMessageEvent()
    }



    func configureCreateMessageEvent() {
//        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.rawValue, sender: nil) { n in
//            guard let status = n.object as? TwitterStatus else {
//                return
//            }
//            guard let keyword = self.keyword else {
//                return
//            }
//            if status.text.containsString(keyword) {
//                self.renderData([status], mode: .TOP, handler: {})
//            }
//        }
    }

    func configureDestroyMessageEvent() {
//        EventBox.onMainThread(self, name: Twitter.Event.DestroyStatus.rawValue, sender: nil) { n in
//            guard let statusID = n.object as? String else {
//                return
//            }
//            let operation = MainBlockOperation { (operation) -> Void in
//                self.adapter.eraseData(self.tableView, statusID: statusID, handler: { () -> Void in
//                    operation.finish()
//                })
//            }
//            self.adapter.mainQueue.addOperation(operation)
//        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return adapter.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return adapter.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return adapter.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
         adapter.tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }

    // MARK: Public Methods

    func loadCache() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let key = "messages:\(account.userID)"
        Async.background {
            if let cache = KeyClip.load(key) as NSDictionary? {
                if let messages = cache["messages"] as? [[String: AnyObject]] {
                    let thread = self.adapter.thread(messages.map({ TwitterMessage($0) }))
                    Async.main {
                        self.adapter.renderData(self.tableView, messages: thread, mode: .OVER, handler: nil)
                        NSLog("messages: loadCache.")
                    }
                    return
                }
            }

            Async.background(after: 0.5, block: { () -> Void in
                self.loadData()
            })
        }
    }

    override func saveCache() {
        if self.adapter.rows.count == 0 {
            return
        }
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let key = "messages:\(account.userID)"
        let messages = self.adapter.messages
        let dictionary = ["messages": ( messages.count > 100 ? Array(messages[0 ..< 100]) : messages ).map({ $0.dictionaryValue })]
        KeyClip.save(key, dictionary: dictionary)
        NSLog("messages: saveCache.")
    }

    func saveCacheSchedule() {
        Scheduler.regsiter(interval: 30, target: self, selector: Selector("saveCache"))
    }

    override func refresh() {
        loadData()
    }

    func loadData() {
        let success = { (messages: [TwitterMessage]) -> Void in
            let thread = self.adapter.thread(messages)
            Async.main {
                self.adapter.renderData(self.tableView, messages: thread, mode: .OVER, handler: nil)
            }
        }
        Twitter.getDirectMessages(success)
    }
}

private extension String {
    var longLongValue: Int64 {
        return (self as NSString).longLongValue
    }
}

private extension Int64 {
    var stringValue: String {
        return String(self)
    }
}
