//
//  SearchesTableViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 2/11/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwiftyJSON
import KeyClip
import EventBox
import Async

class SearchesTableViewController: TimelineTableViewController {

    override var adapter: TwitterStatusAdapter {
        return defaultAdapter
    }
    var nextResults: String?
    var lastID: Int64?
    var keyword: String?
    var cacheLoaded = false
    var keywordStreaming: TwitterSearchStreaming?
    var excludeRetweets = true

//    override func viewDidLoad() {
//        super.viewDidLoad()
//        cacheLoaded = true // no cache
//        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
//    }

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
        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        self.tableView.backgroundColor = UIColor.clearColor()

        adapter.configureView(nil, tableView: tableView)

        adapter.didScrollToBottom = {
            if let nextResults = self.nextResults {
                if let queryItems = NSURLComponents(string: nextResults)?.queryItems {
                    for item in queryItems {
                        if item.name == "max_id" {
                            NSLog("nextResults maxID:\(item.value)")
                            self.loadData(item.value)
                            break
                        }
                    }
                }
            } else if let lastID = self.lastID {
                NSLog("lastID maxID:\(lastID.stringValue)")
                self.loadData((lastID - 1).stringValue)
            }
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(SearchesTableViewController.loadDataToTop), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.adapter.scrollToTop(self.tableView)
        })
        EventBox.onBackgroundThread(self, name: eventFontSizeApplied) { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
            if let fontSize = n.userInfo?["fontSize"] as? NSNumber {
                self.adapter.fontSizeApplied(self.tableView, fontSize: CGFloat(fontSize.floatValue))
            }
        }
        configureCreateStatusEvent()
        configureDestroyStatusEvent()
    }

    func configureCreateStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.rawValue, sender: nil) { n in
            guard let status = n.object as? TwitterStatus else {
                return
            }
            guard let keyword = self.keyword else {
                return
            }
            if status.type != .Normal {
                return
            }
            if status.text.containsString(keyword) {
                self.renderData([status], mode: .TOP, handler: {})
            }
        }
    }

    func configureDestroyStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.DestroyStatus.rawValue, sender: nil) { n in
            guard let statusID = n.object as? String else {
                return
            }
            let operation = MainBlockOperation { (operation) -> Void in
                self.adapter.eraseData(self.tableView, statusID: statusID, handler: { () -> Void in
                    operation.finish()
                })
            }
            self.adapter.mainQueue.addOperation(operation)
        }
    }

    // MARK: Public Methods

    func loadCache() {
        if self.adapter.loadDataQueue.operationCount > 0 {
            return
        }
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (Void-> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in
                for status in statuses {
                    let uniqueID = status.uniqueID.longLongValue
                    if self.lastID == nil || uniqueID < self.lastID! {
                        self.lastID = uniqueID
                    }
                }
                self.renderData(statuses, mode: .OVER, handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            dispatch_sync(dispatch_get_main_queue(), {
                self.adapter.footerIndicatorView?.startAnimating()
                return
            })
            self.loadCache(success, failure: failure)
        })
        self.adapter.loadDataQueue.addOperation(op)
    }

    func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let keyword = self.keyword {
            let key = "searches:\(keyword)"
            Async.background {
                if let cache = KeyClip.load(key) as NSDictionary? {
                    if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                        success(statuses: statuses.map({ TwitterStatus($0) }))
                        return
                    }
                }
                success(statuses: [TwitterStatus]())

                Async.background(after: 0.5, block: { () -> Void in
                    self.loadData(nil)
                })
            }
        } else {
            success(statuses: [])
        }
    }

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            if let keyword = self.keyword {
                let key = "searches:\(keyword)"
                let statuses = self.adapter.statuses
                let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
                KeyClip.save(key, dictionary: dictionary)
                NSLog("searches:\(keyword) saveCache.")
            }
        }
    }

    func saveCacheSchedule() {
        Scheduler.regsiter(interval: 30, target: self, selector: #selector(TimelineTableViewController.saveCache))
    }

    override func refresh() {
        loadData(nil)
    }

    func loadData(maxID: String? = nil) {
        guard let keyword = keyword else {
            ErrorAlert.show("missing keyword")
            return
        }
        if keyword.isEmpty {
            ErrorAlert.show("keyword is empty")
            return
        }
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (Void -> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus], search_metadata: [String: JSON]) -> Void in

                self.nextResults = search_metadata["next_results"]?.string
                self.renderData(statuses, mode: (maxID != nil ? .BOTTOM : .OVER), handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if !(self.refreshControl?.refreshing ?? false) {
                Async.main {
                    self.adapter.footerIndicatorView?.startAnimating()
                    return
                }
            }
            Twitter.getSearchTweets(keyword, maxID: maxID, sinceID: nil, excludeRetweets: self.excludeRetweets, success: success, failure: failure)
        })
        NSLog("keyword:\(keyword) maxID:\(maxID) loadData.")
        self.adapter.loadDataQueue.addOperation(op)
    }

    func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let keyword = keyword else {
            ErrorAlert.show("missing keyword")
            return
        }
        if keyword.isEmpty {
            ErrorAlert.show("keyword is empty")
            return
        }
        let success = { (statuses: [TwitterStatus], searchMetadata: [String: JSON]) -> Void in
            success(statuses: statuses)
        }
        Twitter.getSearchTweets(keyword, maxID: maxID, sinceID: nil, excludeRetweets: self.excludeRetweets, success: success, failure: failure)
    }

    func loadDataToTop() {
        if AccountSettingsStore.get() == nil {
            return
        }

        if self.adapter.rows.count == 0 {
            loadData(nil)
            return
        }

        if self.adapter.loadDataQueue.operationCount > 0 {
            NSLog("loadDataToTop busy")
            return
        }

        NSLog("loadDataToTop addOperation: suspended:\(self.adapter.loadDataQueue.suspended)")
        guard let keyword = keyword else {
            return
        }
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (Void -> Void) = {
                op.finish()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus], search_metadata: [String: JSON]) -> Void in

                // render statuses
                self.renderData(statuses, mode: .HEADER, handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if let sinceID = self.adapter.sinceID() {
                NSLog("loadDataToTop load sinceID:\(sinceID)")
                // self.loadData(sinceID: (sinceID.longLongValue - 1).stringValue, maxID: nil, success: success, failure: failure)
                Twitter.getSearchTweets(keyword, maxID: nil, sinceID: (sinceID.longLongValue - 1).stringValue, excludeRetweets: self.excludeRetweets, success: success, failure: failure)
            } else {
                op.finish()
            }
        })
        self.adapter.loadDataQueue.addOperation(op)
    }

    func renderData(statuses: [TwitterStatus], mode: TwitterStatusAdapter.RenderMode, handler: (() -> Void)?) {
        let operation = MainBlockOperation { (operation) -> Void in
            self.adapter.renderData(self.tableView, statuses: statuses, mode: mode, handler: { () -> Void in
                if self.adapter.isTop {
                    self.adapter.scrollEnd(self.tableView)
                }
                operation.finish()
            })

            if let h = handler {
                h()
            }
        }
        self.adapter.mainQueue.addOperation(operation)
    }
}

extension SearchesTableViewController {
    func addStreamingAction(actionSheet: UIAlertController, tabButton: TabButton) {
        if excludeRetweets {
            actionSheet.addAction(UIAlertAction(title: "Include Retweet", style: .Default, handler: { [weak self] action in
                self?.excludeRetweets = false
                }))
        } else {
            actionSheet.addAction(UIAlertAction(title: "Exclude Retweet", style: .Default, handler: { [weak self] action in
                self?.excludeRetweets = true
                }))
        }

        if let status = keywordStreaming?.status where status == .CONNECTED || status == .CONNECTING {
            actionSheet.addAction(UIAlertAction(title: "Disconnect Search Streaming", style: .Default, handler: { [weak self] action in
                self?.keywordStreaming?.stop()
            }))
        } else {
            guard let keyword = self.keyword where !keyword.isEmpty else {
                return
            }
            actionSheet.addAction(UIAlertAction(title: "Connect Search Streaming", style: .Default, handler: { [weak self] action in
                guard let `self` = self else {
                    return
                }
                guard let account = AccountSettingsStore.get()?.account() else {
                    return
                }
                let receiveStatus = { [weak self] (status: TwitterStatus) -> Void in
                    self?.receiveStatus(status, tabButton: tabButton)
                }
                let connected = { [weak tabButton] () -> Void in
                    tabButton?.streaming = true
                }
                let disconnected = { [weak tabButton] () -> Void in
                    tabButton?.streaming = false
                }
                self.keywordStreaming = TwitterSearchStreaming(
                    account: account,
                    receiveStatus: receiveStatus,
                    connected: connected,
                    disconnected: disconnected).start(keyword)
                }))
        }
    }

    // MARK: - TwitterSearchStreaming

    func receiveStatus(status: TwitterStatus, tabButton: TabButton) {
        if excludeRetweets && status.actionedBy != nil {
            return
        }
        adapter.renderData(tableView, statuses: [status], mode: .TOP, handler: nil)
    }
}
