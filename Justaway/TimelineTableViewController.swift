import UIKit

class TimelineTableViewController: UITableViewController {
    
    var rows = [TwitterStatus]()
    var rowHeight = [String:CGFloat]()
    var patternHeight = [String:CGFloat]()
    var cellForHeight: TwitterStatusCell?
    var maxID: Int64?
    var requestMaxID: Int64?
    
    struct Static {
        private static let queue = NSOperationQueue()
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Static.queue.maxConcurrentOperationCount = 1
        
        self.tableView.separatorInset = UIEdgeInsetsZero
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
        self.tableView.registerNib(nib, forCellReuseIdentifier: "CellForHeight")
        cellForHeight = self.tableView.dequeueReusableCellWithIdentifier("CellForHeight") as? TwitterStatusCell
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as TwitterStatusCell
        let status = rows[indexPath.row]
        
        if let s = cell.status {
            if s.statusID == status.statusID {
                return cell
            }
        }
        
        cell.setText(status)
        
        ImageLoaderClient.displayUserIcon(status.user.profileImageURL, imageView: cell.iconImageView)
        
        cell.status = status
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let status = rows[indexPath.row]
        return rowHeight[status.statusID]!
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row >= (rows.count - 1) {
            scrollToBottom()
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if (Static.queue.suspended) {
            return
        }
        scrollBegin() // now scrolling
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollBegin() // begin of flick scrolling
    }
    
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if (decelerate) {
            return
        }
        scrollEnd() // end of flick scrolling no deceleration
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollEnd() // end of deceleration of flick scrolling
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollEnd() // end of setContentOffset
    }
    
    // MARK: Public Methods
    
    func scrollBegin() {
        Static.queue.suspended = true
    }
    
    func scrollEnd() {
        Static.queue.suspended = false
    }
    
    func scrollToBottom() {
        self.loadData()
    }
    
    func heightForStatus(status: TwitterStatus, fontSize: CGFloat) -> CGFloat {
        let pattern = "normal"
        if let height = patternHeight[pattern] {
            return height + heightForText(status.text, fontSize: fontSize)
        } else if let cell = cellForHeight {
            cell.frame = self.tableView.bounds
            cell.setText(status)
            cell.contentView.setNeedsLayout()
            cell.contentView.layoutIfNeeded()
            let totalHeight = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            let textHeight = heightForText(status.text, fontSize: fontSize)
            patternHeight[pattern] = totalHeight - textHeight
            return totalHeight
        } else {
            assertionFailure("cellForHeight is missing.")
        }
    }
    
    func heightForText(text: NSString, fontSize: CGFloat) -> CGFloat {
        return text.boundingRectWithSize(
            CGSizeMake((self.cellForHeight?.statusLabel.frame.size.width)!, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height
    }
    
    func loadData() {
        if let newRequestMaxID = maxID {
            if newRequestMaxID == requestMaxID {
                return // Duplicate request
            }
            requestMaxID = newRequestMaxID
        }
        
        println(requestMaxID)
        println("request")
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let fontSize = self.cellForHeight?.statusLabel.font.pointSize ?? 12.0
            let success = { (statuses: [TwitterStatus]) -> Void in
                
                // Calc cell height for the all statuses
                for status in statuses {
                    let statusID = (status.statusID as NSString).longLongValue
                    if (self.maxID == nil || statusID < self.maxID!) {
                        self.maxID = statusID - 1
                    }
                    println(self.maxID)
                    self.rowHeight[status.statusID] = self.heightForStatus(status, fontSize: fontSize)
                }
                
                // Set statuses
                self.rows = self.rows + statuses
                
                // Show tweets
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableView.reloadData()
                    op.finish()
                })
            }
            let failure = { (error: NSError) in
                op.finish()
            }
            Twitter.getHomeTimeline(self.requestMaxID, success: success, failure: failure)
        })
        Static.queue.addOperation(op)
    }
    
}
