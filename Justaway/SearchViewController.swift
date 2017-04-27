//
//  SearchViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/29/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwiftyJSON
import Async
import EventBox

class SearchViewController: UIViewController {

    // MARK: Properties

    let refreshControl = UIRefreshControl()
    let adapter = TwitterStatusAdapter()
    let keywordAdapter = SearchKeywordAdapter()
    var keywordStreaming: TwitterSearchStreaming?
    let userAdapter = TwitterUserAdapter()
    var nextResults: String?
    var nextPage: Int?
    var keyword: String?
    var excludeRetweets = true

    @IBOutlet weak var tweetsTableView: UITableView!
    @IBOutlet weak var usersTableView: UITableView!
    @IBOutlet weak var keywordTableView: UITableView!
    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var streamingButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!

    override var nibName: String {
        return "SearchViewController"
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
        keywordTextField.text = keyword
        if let keyword = keyword, !keyword.isEmpty {
            keywordTextField.rightViewMode = .always
            loadData()
            keywordAdapter.appendHistory(keyword, tableView: keywordTableView)
            streamingButton.isEnabled = true
        } else {
            keywordTextField.becomeFirstResponder()
            keywordTextField.rightViewMode = .never
            keywordTableView.isHidden = false
            streamingButton.isEnabled = false
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for c in tweetsTableView.visibleCells {
            if let cell = c as? TwitterStatusCell {
                cell.statusLabel.setAttributes()
            }
        }

    }

    // MARK: - Configuration

    func configureView() {
        refreshControl.addTarget(self, action: #selector(loadDataToTop), for: UIControlEvents.valueChanged)
        tweetsTableView.addSubview(refreshControl)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(hide))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .right
        tweetsTableView.panGestureRecognizer.require(toFail: swipe)
        tweetsTableView.addGestureRecognizer(swipe)

        adapter.configureView(nil, tableView: tweetsTableView)
        adapter.didScrollToBottom = {
            if let nextResults = self.nextResults {
                if let queryItems = URLComponents(string: nextResults)?.queryItems {
                    for item in queryItems {
                        if item.name == "max_id" {
                            self.loadData(item.value)
                            break
                        }
                    }
                }
            }
        }

        userAdapter.configureView(usersTableView)
        userAdapter.didScrollToBottom = {
            if let nextPage = self.nextPage {
                self.nextPage = nil
                self.loadUserData(nextPage)
            }
        }

        usersTableView.panGestureRecognizer.require(toFail: swipe)
        usersTableView.addGestureRecognizer(swipe)

        let button = MenuButton()
        button.tintColor = UIColor.clear
        button.titleLabel?.font = UIFont(name: "fontello", size: 16.0)
        button.frame = CGRect(x: 0, y: 0, width: 32, height: 32)
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        button.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        button.setTitle("✖", for: UIControlState())
        button.addTarget(self, action: #selector(clear), for: .touchUpInside)
        keywordTextField.addTarget(self, action: #selector(change), for: .editingChanged)
        keywordTextField.rightView = button
        keywordTextField.rightViewMode = .always

        keywordAdapter.configureView(keywordTableView)
        keywordAdapter.selectCallback = { [weak self] (keyword) -> Void in
            guard let `self` = self else {
                return
            }
            self.keywordAdapter.appendHistory(keyword, tableView: self.keywordTableView)
            self.keywordTextField.text = keyword
            self.keyword = keyword
            self.loadData()
            self.keywordTextField.resignFirstResponder()
        }
        keywordAdapter.scrollCallback = { [weak self] in
            self?.keywordTextField.resignFirstResponder()
        }

        streamingButton.setTitleColor(ThemeController.currentTheme.bodyTextColor(), for: UIControlState())
    }

    func loadData(_ maxID: String? = nil) {
        guard let keyword = keyword else {
            return
        }
        if keyword.isEmpty {
            return
        }
        keywordTableView.isHidden = true
        if segmentedControl.selectedSegmentIndex > 1 {
            tweetsTableView.isHidden = true
            usersTableView.isHidden = false
            loadUserData()
            return
        }
        tweetsTableView.isHidden = false
        usersTableView.isHidden = true
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: ((Void) -> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus], search_metadata: [String: JSON]) -> Void in

                self.nextResults = search_metadata["next_results"]?.string
                self.renderData(statuses, mode: (maxID != nil ? .bottom : .over), handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if !self.refreshControl.isRefreshing {
                Async.main {
                    self.adapter.footerIndicatorView?.startAnimating()
                    return
                }
            }
            let resultType = self.segmentedControl.selectedSegmentIndex == 0 ? "recent" : "popular"
            Twitter.getSearchTweets(keyword, maxID: maxID, sinceID: nil, excludeRetweets: self.excludeRetweets, resultType: resultType, success: success, failure: failure)
        })
        self.adapter.loadDataQueue.addOperation(op)
    }

    func loadDataToTop() {
        if AccountSettingsStore.get() == nil {
            return
        }

        if self.adapter.rows.count == 0 {
            loadData()
            return
        }

        if self.adapter.loadDataQueue.operationCount > 0 {
            NSLog("loadDataToTop busy")
            return
        }

        if segmentedControl.selectedSegmentIndex > 1 {
            return
        }

        NSLog("loadDataToTop addOperation: suspended:\(self.adapter.loadDataQueue.isSuspended)")
        guard let keyword = keyword else {
            return
        }
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: ((Void) -> Void) = {
                op.finish()
                self.refreshControl.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus], search_metadata: [String: JSON]) -> Void in

                // render statuses
                self.renderData(statuses, mode: .header, handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if let sinceID = self.adapter.sinceID() {
                NSLog("loadDataToTop load sinceID:\(sinceID)")
                let resultType = self.segmentedControl.selectedSegmentIndex == 0 ? "recent" : "popular"
                Twitter.getSearchTweets(keyword, maxID: nil, sinceID: (sinceID.longLongValue - 1).stringValue, excludeRetweets: self.excludeRetweets, resultType: resultType, success: success, failure: failure)
            } else {
                op.finish()
            }
        })
        self.adapter.loadDataQueue.addOperation(op)
    }

    func renderData(_ statuses: [TwitterStatus], mode: TwitterStatusAdapter.RenderMode, handler: (() -> Void)?) {
        let operation = MainBlockOperation { (operation) -> Void in
            self.adapter.renderData(self.tweetsTableView, statuses: statuses, mode: mode, handler: { () -> Void in
                if self.adapter.isTop {
                    self.adapter.scrollEnd(self.tweetsTableView)
                }
                operation.finish()
            })

            if let h = handler {
                h()
            }
        }
        self.adapter.mainQueue.addOperation(operation)
    }

    func loadUserData(_ page: Int = 1) {
        guard let keyword = keyword else {
            return
        }
        if keyword.isEmpty {
            return
        }
        keywordTableView.isHidden = true
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: ((Void) -> Void) = {
                op.finish()
                self.userAdapter.footerIndicatorView?.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            let success = { (users: [TwitterUserFull]) -> Void in
                if users.count > 0 {
                    self.nextPage = page + 1
                }
                self.renderUserData(users, mode: (page > 1 ? .bottom : .over), handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if !self.refreshControl.isRefreshing {
                Async.main {
                    self.userAdapter.footerIndicatorView?.startAnimating()
                    return
                }
            }
            Twitter.getUsers(keyword, page: page, success: success, failure: failure)
        })
        self.userAdapter.loadDataQueue.addOperation(op)
    }

    func renderUserData(_ users: [TwitterUserFull], mode: TwitterStatusAdapter.RenderMode, handler: (() -> Void)?) {
        let operation = MainBlockOperation { (operation) -> Void in
            self.userAdapter.renderData(self.usersTableView, users: users, mode: mode, handler: { () -> Void in
//                if self.userAdapter.isTop {
//                    self.userAdapter.scrollEnd(self.tweetsTableView)
//                }
                operation.finish()
            })

            if let h = handler {
                h()
            }
        }
        self.userAdapter.mainQueue.addOperation(operation)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.adapter.scrollToTop(self.tweetsTableView)
        })
        EventBox.onMainThread(self, name: NSNotification.Name.UIKeyboardWillShow) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: true)
        }

        EventBox.onMainThread(self, name: NSNotification.Name.UIKeyboardWillHide) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: false)
        }
        configureCreateStatusEvent()
        configureDestroyStatusEvent()
    }

    func configureCreateStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.Name(), sender: nil) { n in
            guard let status = n.object as? TwitterStatus else {
                return
            }
            guard let keyword = self.keyword else {
                return
            }
            if status.text.contains(keyword) {
                self.renderData([status], mode: .top, handler: {})
            }
        }
    }

    func configureDestroyStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.DestroyStatus.Name(), sender: nil) { n in
            guard let statusID = n.object as? String else {
                return
            }
            let operation = MainBlockOperation { (operation) -> Void in
                self.adapter.eraseData(self.tweetsTableView, statusID: statusID, handler: { () -> Void in
                    operation.finish()
                })
            }
            self.adapter.mainQueue.addOperation(operation)
        }
    }

    // MARK: - Actions

    func keyboardWillChangeFrame(_ notification: Notification, showsKeyboard: Bool) {
        if showsKeyboard {
            keywordTableView.isHidden = false
            keywordAdapter.loadData(keywordTableView)
        }
        change()
    }

    @IBAction func menu(_ sender: UIView) {
        if keywordTextField.isFirstResponder {
            keywordTextField.resignFirstResponder()
            return
        }
        guard let keyword = keywordTextField.text else {
            return
        }
        if keyword.isEmpty {
            MessageAlert.show("Please input keyword")
            return
        }
        if segmentedControl.selectedSegmentIndex > 1 {
            return
        }
        showMenu(sender, keyword: keyword)
    }

    @IBAction func streaming(_ sender: AnyObject) {
        if let status = keywordStreaming?.status, status == .connected || status == .connecting {
            let alert = UIAlertController(title: "Disconnect search streaming?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
                self?.keywordStreaming?.stop()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            AlertController.showViewController(alert)
            return
        }
        guard let keyword = self.keyword, !keyword.isEmpty else {
            return
        }
        if segmentedControl.selectedSegmentIndex > 1 {
            return
        }
        let alert = UIAlertController(title: "Connect search streaming?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] action in
            guard let `self` = self else {
                return
            }
            guard let account = AccountSettingsStore.get()?.account() else {
                return
            }
            self.keywordStreaming = TwitterSearchStreaming(
                account: account,
                receiveStatus: self.receiveStatus,
                connected: self.connectStreaming,
                disconnected: self.disconnectStreaming).start(keyword)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        AlertController.showViewController(alert)
    }

    @IBAction func search(_ sender: AnyObject) {
        guard let keyword = keywordTextField.text else {
            NSLog("no data")
            return
        }
        if keyword.isEmpty {
            NSLog("empty")
            return
        }
        NSLog("search")
        self.keyword = keyword
        loadData()
        keywordAdapter.appendHistory(keyword, tableView: keywordTableView)
    }

    @IBAction func left(_ sender: UIButton) {
        if keywordTextField.isFirstResponder {
            keywordTextField.resignFirstResponder()
        }
        hide()
    }

    @IBAction func post(_ sender: AnyObject) {
        guard let keyword = keyword else {
            return
        }
        EditorViewController.show(" " + keyword, range: NSRange(location: 0, length: 0), inReplyToStatus: nil)
    }

    @IBAction func segmentedChange(_ sender: AnyObject) {

    }

    func clear() {
        keywordTextField.text = ""
        keywordTextField.rightViewMode = .never
    }

    func change() {
        if keywordTextField.text?.isEmpty ?? true {
            keywordTextField.rightViewMode = .never
            streamingButton.isEnabled = false
        } else {
            keywordTextField.rightViewMode = .always
            streamingButton.isEnabled = true
        }
    }

    func hide() {
        keywordStreaming?.stop()
        ViewTools.slideOut(self)
    }

    // MARK: - TwitterSearchStreaming

    func receiveStatus(_ status: TwitterStatus) {
        if excludeRetweets && status.actionedBy != nil {
            return
        }
        adapter.renderData(tweetsTableView, statuses: [status], mode: .top, handler: nil)
    }

    func connectStreaming() {
        streamingButton.setTitleColor(ThemeController.currentTheme.streamingConnected(), for: UIControlState())
    }

    func disconnectStreaming() {
        streamingButton.setTitleColor(ThemeController.currentTheme.bodyTextColor(), for: UIControlState())
    }

    // MARK: - Class Methods

    class func show(_ keyword: String) {
        let instance = SearchViewController()
        instance.keyword = keyword
        ViewTools.slideIn(instance)
    }
}
