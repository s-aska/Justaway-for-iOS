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

    let messageAdapter = TwitterMessageAdapter(threadMode: true)
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
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
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
        configureCreateMessageEvent()
        configureDestroyMessageEvent()
    }



    func configureCreateMessageEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateMessage.rawValue) { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            guard let messages = Twitter.messages[account.userID] else {
                return
            }
            let thread = self.adapter.thread(messages)
            Async.main {
                self.adapter.renderData(self.tableView, messages: thread, mode: .OVER, handler: nil)
            }
        }
    }

    func configureDestroyMessageEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.DestroyMessage.rawValue) { [weak self] (n) -> Void in
            guard let `self` = self else {
                return
            }
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            guard let messages = Twitter.messages[account.userID] else {
                return
            }
            let thread = self.adapter.thread(messages)
            Async.main {
                self.adapter.renderData(self.tableView, messages: thread, mode: .OVER, handler: nil)
            }
        }
    }

    // MARK: Public Methods

    func loadCache() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let key = "messages:\(account.userID)"
        Async.background {
            if let cache = KeyClip.load(key) as NSDictionary? {
                if let array = cache["messages"] as? [[String: AnyObject]] {
                    let messages = array.map({ TwitterMessage($0, ownerID: account.userID) })
                    Twitter.messages.updateValue(messages, forKey: account.userID)
                    let thread = self.adapter.thread(messages)
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
        guard let messages = Twitter.messages[account.userID] else {
            return
        }
        let dictionary = ["messages": ( messages.count > 200 ? Array(messages[0 ..< 200]) : messages ).map({ $0.dictionaryValue })]
        KeyClip.save(key, dictionary: dictionary)
        NSLog("messages: saveCache.")
    }

    func saveCacheSchedule() {
        Scheduler.regsiter(interval: 30, target: self, selector: #selector(saveCache))
    }

    override func refresh() {
        loadData()
    }

    func loadData() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let success = { (messages: [TwitterMessage]) -> Void in
            Twitter.messages.updateValue(messages, forKey: account.userID)
            let thread = self.adapter.thread(messages)
            Async.main {
                self.adapter.renderData(self.tableView, messages: thread, mode: .OVER, handler: nil)
            }
        }
        Twitter.getDirectMessages(success)
    }
}
