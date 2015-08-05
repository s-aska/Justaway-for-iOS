import UIKit
import SwifteriOS
import EventBox
import KeyClip
import Pinwheel

let TIMELINE_ROWS_LIMIT = 1000
let TIMELINE_FOOTER_HEIGHT: CGFloat = 40

class StatusTableViewController: TimelineTableViewController {
    
    let adapter = TwitterStatusAdapter()
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
        
        adapter.configureView(tableView)
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
    }
    
    func configureEvent() {
        EventBox.onBackgroundThread(self, name: "applicationDidEnterBackground") { (n) -> Void in
            self.saveCache()
        }
        EventBox.onMainThread(self, name: EventStatusBarTouched, handler: { (n) -> Void in
            self.scrollToTop()
        })
        EventBox.onBackgroundThread(self, name: EventFontSizeApplied) { (n) -> Void in
            if let fontSize = n.userInfo?["fontSize"] as? NSNumber {
                let newNows = self.adapter.rows.map({ self.adapter.createRow($0.status, fontSize: CGFloat(fontSize.floatValue), tableView: self.tableView) })
                
                let op = AsyncBlockOperation { (op) -> Void in
                    if var firstCell = self.tableView.visibleCells.first {
                        var offset = self.tableView.contentOffset.y - firstCell.frame.origin.y
                        var firstPath: NSIndexPath
                        
                        // セルが半分以上隠れているている場合、2番目の表示セルを基準にする
                        if let indexPathsForVisibleRows = self.tableView.indexPathsForVisibleRows {
                            if indexPathsForVisibleRows.count > 1 && offset > (firstCell.frame.size.height / 2) {
                                firstPath = indexPathsForVisibleRows[1]
                                firstCell = self.tableView.cellForRowAtIndexPath(firstPath)!
                                offset = self.tableView.contentOffset.y - firstCell.frame.origin.y
                            } else {
                                firstPath = indexPathsForVisibleRows.first!
                            }
                            
                            self.adapter.rows = newNows
                            
                            self.tableView.reloadData()
                            self.tableView.scrollToRowAtIndexPath(firstPath, atScrollPosition: .Top, animated: false)
                            self.tableView.setContentOffset(CGPointMake(0, self.tableView.contentOffset.y + offset), animated: false)
                        }
                    }
                    op.finish()
                }
                self.mainQueue.addOperation(op)
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.adapter.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return self.adapter.tableView(tableView, cellForRowAtIndexPath: indexPath)
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.adapter.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.adapter.tableView(tableView, didSelectRowAtIndexPath: indexPath)
    }
    
    // MARK: Public Methods
    
    override func didScrollToBottom() {
        if let maxID = lastID {
            self.loadData(maxID - 1)
        }
    }
    
    func loadCache() {
        if loadDataQueue.operationCount > 0 {
            return
        }
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (()-> Void) = {
                op.finish()
                self.footerIndicatorView?.stopAnimating()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in
                for status in statuses {
                    let uniqueID = status.uniqueID.longLongValue
                    if (self.lastID == nil || uniqueID < self.lastID!) {
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
                self.footerIndicatorView?.startAnimating()
                return
            })
            self.loadCache(success, failure: failure)
        })
        loadDataQueue.addOperation(op)
    }
    
    func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
    
    func saveCache() {
        assertionFailure("not implements.")
    }
    
    func saveCacheSchedule() {
        Scheduler.regsiter(min: 30, max: 60, target: self, selector: Selector("saveCache"))
    }
    
    override func refresh() {
        loadData(nil)
    }
    
    func loadData(maxID: Int64?) {
        if loadDataQueue.operationCount > 0 {
            NSLog("loadData busy")
            return
        }
        if maxID == nil {
            self.lastID = nil
        }
        NSLog("loadData addOperation: \(maxID ?? 0) suspended:\(loadDataQueue.suspended)")
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (()-> Void) = {
                op.finish()
                self.footerIndicatorView?.stopAnimating()
                self.refreshControl?.endRefreshing()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in
                
                // Calc cell height for the all statuses
                for status in statuses {
                    let uniqueID = status.uniqueID.longLongValue
                    if (self.lastID == nil || uniqueID < self.lastID!) {
                        self.lastID = uniqueID
                    }
                }
                
                // render statuses
                self.renderData(statuses, mode: (maxID != nil ? .BOTTOM : .OVER), handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if !(self.refreshControl?.refreshing ?? false) {
                Async.main {
                    self.footerIndicatorView?.startAnimating()
                    return
                }
            }
            self.loadData(maxID?.stringValue, success: success, failure: failure)
        })
        loadDataQueue.addOperation(op)
    }
    
    func loadData(id: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        assertionFailure("not implements.")
    }
    
    func accept(status: TwitterStatus) -> Bool {
        fatalError("not implements.")
    }
    
    func renderData(statuses: [TwitterStatus], mode: TwitterStatusAdapter.RenderMode, handler: (() -> Void)?) {
        let op = AsyncBlockOperation { (op) -> Void in
            self.adapter.renderData(self.tableView, statuses: statuses, mode: mode, handler: { () -> Void in
                if self.isTop {
                    self.scrollEnd()
                }
                self.saveCacheSchedule()
                op.finish()
            })
            
            if let h = handler {
                h()
            }
        }
        mainQueue.addOperation(op)
    }
    
    func eraseData(statusID: String, handler: (() -> Void)?) {
        let op = AsyncBlockOperation { (op) -> Void in
            self.adapter.eraseData(self.tableView, statusID: statusID, handler: { () -> Void in
                op.finish()
            })
            
            if let h = handler {
                h()
            }
        }
        mainQueue.addOperation(op)
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
