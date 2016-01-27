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

class SearchViewController: UIViewController {

    // MARK: Properties

    let refreshControl = UIRefreshControl()
    let adapter = TwitterStatusAdapter()
    var nextResults: String?
    var keyword: String?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var keywordLabel: MenuLable!

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
        loadData()
        keywordLabel.text = keyword
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        // TODO
        // refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)


        let swipe = UISwipeGestureRecognizer(target: self, action: "hide")
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
    }

    func loadData(maxID: String? = nil) {
        guard let keyword = keyword else {
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
            // self.loadData(maxID?.stringValue, success: success, failure: failure)
            Twitter.getSearchTweets(keyword, maxID: maxID, sinceID: nil, success: success, failure: failure)
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

    }

    // MARK: - Actions

    @IBAction func left(sender: UIButton) {
        hide()
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
