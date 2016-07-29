import UIKit
import EventBox
import KeyClip
import Async

let timelineRowsLimit = 1000
let timelineHooterHeight: CGFloat = 40

class StatusTableViewController: TimelineTableViewController, TwitterStatusAdapterDelegate {

    override var adapter: TwitterStatusAdapter {
        return defaultAdapter
    }

    var lastID: Int64?
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
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        self.tableView.backgroundColor = UIColor.clearColor()

        adapter.configureView(self, tableView: tableView)

        adapter.didScrollToBottom = {
            if let status = self.adapter.statuses.last {
                self.loadData(status.statusID.longLongValue - 1)
            }
        }

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(StatusTableViewController.loadDataToTop), forControlEvents: UIControlEvents.ValueChanged)
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
                ErrorAlert.show(error)
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
        assertionFailure("not implements.")
    }

    func saveCacheSchedule() {
        Scheduler.regsiter(interval: 30, target: self, selector: #selector(saveCache))
    }

    override func refresh() {
        loadData(nil)
    }

    func loadData(maxID: Int64?) {
        if self.adapter.loadDataQueue.operationCount > 0 {
            NSLog("loadData busy")
            return
        }
        if maxID == nil {
            self.lastID = nil
        }
        NSLog("loadData addOperation: \(maxID ?? 0) suspended:\(self.adapter.loadDataQueue.suspended)")
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (Void -> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in

                // Calc cell height for the all statuses
                for status in statuses {
                    let uniqueID = status.uniqueID.longLongValue
                    if self.lastID == nil || uniqueID < self.lastID! {
                        self.lastID = uniqueID
                    }
                }

                // render statuses
                self.renderData(statuses, mode: (maxID != nil ? .BOTTOM : .OVER), handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show(error)
                always()
            }
            if !(self.refreshControl?.refreshing ?? false) {
                Async.main {
                    self.adapter.footerIndicatorView?.startAnimating()
                    return
                }
            }
            self.loadData(maxID?.stringValue, success: success, failure: failure)
        })
        self.adapter.loadDataQueue.addOperation(op)
    }

    func loadData(maxID: String? = nil, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }

    func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        success(statuses: [TwitterStatus]())
    }

    func loadDataToTop() {
        if AccountSettingsStore.get() == nil {
            return
        }

        if self.adapter.rows.count == 0 {
            refresh()
            return
        }

        if self.adapter.loadDataQueue.operationCount > 0 {
            NSLog("loadDataToTop busy")
            return
        }

        NSLog("loadDataToTop addOperation: suspended:\(self.adapter.loadDataQueue.suspended)")

        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (Void -> Void) = {
                op.finish()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in

                // render statuses
                self.renderData(statuses, mode: .HEADER, handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show(error)
                always()
            }
            if let topSinceID = self.adapter.sinceID() {
                NSLog("loadDataToTop load sinceID:\(topSinceID)")
                // "Show more tweets" are and need the same id
                let sinceID = self.adapter.activityMode ? topSinceID : (topSinceID.longLongValue - 1).stringValue
                self.loadData(sinceID: sinceID, maxID: nil, success: success, failure: failure)
            } else {
                op.finish()
            }
        })
        self.adapter.loadDataQueue.addOperation(op)
    }

    func accept(status: TwitterStatus) -> Bool {
        fatalError("not implements.")
    }

    func renderData(statuses: [TwitterStatus], mode: TwitterStatusAdapter.RenderMode, handler: (() -> Void)?) {
        let operation = MainBlockOperation { (operation) -> Void in
            self.adapter.renderData(self.tableView, statuses: statuses, mode: mode, handler: { () -> Void in
                if self.adapter.scrolling {
                    Async.main(after: 0.1, block: { () -> Void in
                        self.adapter.scrollEnd(self.tableView)
                    })
                }
                operation.finish()
            })

            if let h = handler {
                h()
            }
        }
        self.adapter.mainQueue.addOperation(operation)
    }

    func eraseData(statusID: String, handler: (() -> Void)?) {
        let operation = MainBlockOperation { (operation) -> Void in
            self.adapter.eraseData(self.tableView, statusID: statusID, handler: { () -> Void in
                operation.finish()
            })

            if let h = handler {
                h()
            }
        }
        self.adapter.mainQueue.addOperation(operation)
    }
}
