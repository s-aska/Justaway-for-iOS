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

    // MARK: Types

    struct Static {
        static var instances = [SearchViewController]()
    }

    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }

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
        let operation = AsyncBlockOperation { (operation) -> Void in
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
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            self.view.frame = CGRect.init(
                x: self.view.frame.size.width,
                y: self.view.frame.origin.y,
                width: self.view.frame.size.width,
                height: self.view.frame.size.height)
            }, completion: { finished in
                self.view.hidden = true
                self.view.removeFromSuperview()
                Static.instances.removeAtIndex(Static.instances.endIndex.predecessor()) // purge instance
        })
    }

    // MARK: - Class Methods

    class func show(keyword: String) {

        EditorViewController.hide() // TODO: think seriously about

        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            let instance = SearchViewController()
            instance.keyword = keyword
            instance.view.hidden = true
            vc.view.addSubview(instance.view)
            instance.view.frame = CGRect.init(x: vc.view.frame.width, y: 0, width: vc.view.frame.width, height: vc.view.frame.height)
            instance.view.hidden = false

            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
                instance.view.frame = CGRect.init(x: 0,
                    y: vc.view.frame.origin.y,
                    width: vc.view.frame.size.width,
                    height: vc.view.frame.size.height)
                }) { (finished) -> Void in
            }
            Static.instances.append(instance) // keep instance
        }
    }
}
