import UIKit
import EventBox
import KeyClip
import Pinwheel

let TIMELINE_ROWS_LIMIT = 1000
let TIMELINE_FOOTER_HEIGHT: CGFloat = 40

class StatusTableViewController: TimelineTableViewController {
    
    let adapter = TwitterStatusAdapter()
    var lastID: Int64?
    var cacheLoaded = false
    var lastUpdated: NSTimeInterval = 0
    
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
        
        adapter.didScrollToBottom = {
            if let status = self.adapter.rows.last {
                self.loadData(status.status.statusID.longLongValue - 1)
            }
        }
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        self.refreshControl = refreshControl
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: EventStatusBarTouched, handler: { (n) -> Void in
            self.adapter.scrollToTop(self.tableView)
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
                self.adapter.mainQueue.addOperation(op)
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
            let always: (()-> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
                self.refreshControl?.endRefreshing()
                self.loadDataInSleep()
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
    
    func saveCache() {
        assertionFailure("not implements.")
    }
    
    func saveCacheSchedule() {
        Scheduler.regsiter(interval: 30, target: self, selector: Selector("saveCache"))
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
            let always: (()-> Void) = {
                op.finish()
                self.adapter.footerIndicatorView?.stopAnimating()
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
    
    func loadData(sinceID sinceID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        success(statuses: [TwitterStatus]())
    }
    
    func sinceID() -> String? {
        return self.adapter.rows.first?.status.statusID
    }
    
    func loadDataInSleep() {
        if AccountSettingsStore.get() == nil {
            return
        }
        
        if self.adapter.loadDataQueue.operationCount > 0 {
            NSLog("loadDataInSleep busy")
            return
        }
        
        let elapsed = NSDate().timeIntervalSince1970 - lastUpdated
        if elapsed < 30 {
            NSLog("loadDataInSleep short")
            return
        }
        
        lastUpdated = NSDate().timeIntervalSince1970
        
        NSLog("loadDataInSleep addOperation: suspended:\(self.adapter.loadDataQueue.suspended)")
        
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (()-> Void) = {
                op.finish()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in
                
                // render statuses
                self.renderData(statuses, mode: .HEADER, handler: always)
            }
            let failure = { (error: NSError) -> Void in
                ErrorAlert.show("Error", message: error.localizedDescription)
                always()
            }
            if let sinceID = self.sinceID() {
                NSLog("loadDataInSleep load sinceID:\(sinceID)")
                self.loadData(sinceID: sinceID, success: success, failure: failure)
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
        let op = AsyncBlockOperation { (op) -> Void in
            self.adapter.renderData(self.tableView, statuses: statuses, mode: mode, handler: { () -> Void in
                if self.adapter.isTop {
                    self.adapter.scrollEnd(self.tableView)
                }
                op.finish()
            })
            
            if let h = handler {
                h()
            }
        }
        self.adapter.mainQueue.addOperation(op)
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
        self.adapter.mainQueue.addOperation(op)
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
