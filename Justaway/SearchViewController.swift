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
    var nextResults: String?
    var keyword: String?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var cover: UIView!
    // @IBOutlet weak var keywordLabel: MenuLable!


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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
        cover.hidden = true
        keywordTextField.text = keyword
        if keyword?.isEmpty ?? true {
            keywordTextField.becomeFirstResponder()
            keywordTextField.rightViewMode = .Never
        } else {
            keywordTextField.rightViewMode = .Always
            loadData()
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        refreshControl.addTarget(self, action: #selector(SearchViewController.loadDataToTop), forControlEvents: UIControlEvents.ValueChanged)
        tableView.addSubview(refreshControl)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(SearchViewController.hide))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .Right
        tableView.panGestureRecognizer.requireGestureRecognizerToFail(swipe)
        tableView.addGestureRecognizer(swipe)

        adapter.configureView(nil, tableView: tableView)
        adapter.didScrollToBottom = {
            if let nextResults = self.nextResults {
                if let queryItems = NSURLComponents(string: nextResults)?.queryItems {
                    for item in queryItems {
                        if item.name == "max_id" {
                            self.loadData(item.value)
                            break
                        }
                    }
                }
            }
        }

        let touchCover = UITapGestureRecognizer(target: keywordTextField, action: #selector(UIResponder.resignFirstResponder))
        cover.addGestureRecognizer(touchCover)

        let button = MenuButton()
        button.tintColor = UIColor.clearColor()
        button.titleLabel?.font = UIFont(name: "fontello", size: 16.0)
        button.frame = CGRect.init(x: 0, y: 0, width: 32, height: 32)
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        button.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        button.setTitle("✖", forState: UIControlState.Normal)
        button.addTarget(self, action: #selector(SearchViewController.clear), forControlEvents: .TouchUpInside)
        keywordTextField.addTarget(self, action: #selector(SearchViewController.change), forControlEvents: .EditingChanged)
        keywordTextField.rightView = button
        keywordTextField.rightViewMode = .Always
    }

    func loadData(maxID: String? = nil) {
        guard let keyword = keyword else {
            return
        }
        if keyword.isEmpty {
            return
        }
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (Void -> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
                self.refreshControl.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus], search_metadata: [String: JSON]) -> Void in

                self.nextResults = search_metadata["next_results"]?.string
                self.renderData(statuses, mode: (maxID != nil ? .BOTTOM : .OVER), handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if !self.refreshControl.refreshing {
                Async.main {
                    self.adapter.footerIndicatorView?.startAnimating()
                    return
                }
            }
            Twitter.getSearchTweets(keyword, maxID: maxID, sinceID: nil, success: success, failure: failure)
        })
        self.adapter.loadDataQueue.addOperation(op)
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
                self.refreshControl.endRefreshing()
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
                Twitter.getSearchTweets(keyword, maxID: nil, sinceID: (sinceID.longLongValue - 1).stringValue, success: success, failure: failure)
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

    func configureEvent() {
        EventBox.onMainThread(self, name: eventStatusBarTouched, handler: { (n) -> Void in
            self.adapter.scrollToTop(self.tableView)
        })
        EventBox.onMainThread(self, name: UIKeyboardWillShowNotification) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: true)
        }

        EventBox.onMainThread(self, name: UIKeyboardWillHideNotification) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: false)
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

    // MARK: - Actions

    func keyboardWillChangeFrame(notification: NSNotification, showsKeyboard: Bool) {
        cover.hidden = !showsKeyboard
        change()
    }

    @IBAction func menu(sender: UIView) {
        if keywordTextField.isFirstResponder() {
            keywordTextField.resignFirstResponder()
            return
        }
        guard let keyword = keywordTextField.text else {
            return
        }
        SearchAlert.show(sender, keyword: keyword)
    }

    @IBAction func search(sender: AnyObject) {
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
        loadData(nil)
    }

    @IBAction func left(sender: UIButton) {
        hide()
    }

    @IBAction func post(sender: AnyObject) {
        guard let keyword = keyword else {
            return
        }
        EditorViewController.show(" " + keyword, range: NSRange(location: 0, length: 0), inReplyToStatus: nil)
    }

    func clear() {
        keywordTextField.text = ""
        keywordTextField.rightViewMode = .Never
    }

    func change() {
        if keywordTextField.text?.isEmpty ?? true {
            keywordTextField.rightViewMode = .Never
        } else {
            keywordTextField.rightViewMode = .Always
        }
    }

    func hide() {
        ViewTools.slideOut(self)
    }

    // MARK: - Class Methods

    class func show(keyword: String) {
        let instance = SearchViewController()
        instance.keyword = keyword
        ViewTools.slideIn(instance)
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
