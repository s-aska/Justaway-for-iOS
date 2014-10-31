import UIKit
import SwifteriOS

let TIMELINE_ROWS_LIMIT = 1000
let TIMELINE_FOOTER_HEIGHT: CGFloat = 40

class TimelineTableViewController: UITableViewController {
    
    var rows = [TwitterStatus]()
    var rowHeight = [String:CGFloat]()
    var layoutHeight = [TwitterStatusCellLayout: CGFloat]()
    var layoutHeightCell = [TwitterStatusCellLayout: TwitterStatusCell]()
    var lastID: Int64?
    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?
    var isTop: Bool = true
    
    enum RenderMode {
        case TOP
        case BOTTOM
        case OVER
    }
    
    struct Static {
        private static let loadDataQueue = NSOperationQueue()
        private static let mainQueue = NSOperationQueue.mainQueue()
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Static.loadDataQueue.maxConcurrentOperationCount = 1
        Static.mainQueue.maxConcurrentOperationCount = 1
        
        self.tableView.separatorInset = UIEdgeInsetsZero
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        for layout in TwitterStatusCellLayout.allValues {
            self.tableView.registerNib(nib, forCellReuseIdentifier: layout.rawValue)
            self.layoutHeightCell[layout] = self.tableView.dequeueReusableCellWithIdentifier(layout.rawValue) as? TwitterStatusCell
        }
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let status = rows[indexPath.row]
        let layout = TwitterStatusCellLayout.fromStatus(status)
        let cell = tableView.dequeueReusableCellWithIdentifier(layout.rawValue, forIndexPath: indexPath) as TwitterStatusCell
        
        if let s = cell.status {
            if s.statusID == status.statusID {
                return cell
            }
        }
        
        cell.status = status
        cell.setLayout(layout)
        cell.setText(status)
        
        ImageLoaderClient.displayUserIcon(status.user.profileImageURL, imageView: cell.iconImageView)
        
        if let actionedBy = status.actionedBy {
            ImageLoaderClient.displayActionedUserIcon(actionedBy.profileImageURL, imageView: cell.actionedIconImageView)
        }
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let status = rows[indexPath.row]
        return rowHeight[status.statusID]!
    }
    
//    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//        if indexPath.row >= (rows.count - 1) {
//            didScrollToBottom()
//        }
//    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return TIMELINE_FOOTER_HEIGHT
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = UIView(frame: CGRectMake(0, 0, view.frame.size.width, TIMELINE_FOOTER_HEIGHT))
            footerIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
            footerView?.addSubview(footerIndicatorView!)
            footerIndicatorView?.hidesWhenStopped = true
            footerIndicatorView?.center = (footerView?.center)!
        }
        return footerView
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if (Static.loadDataQueue.suspended) {
            return
        }
        scrollBegin() // now scrolling
    }
    
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        isTop = false
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
    
    func toggleStreaming() {
        let progress = {
            (data: [String: JSONValue]?) -> Void in
            
            if data == nil {
                return
            }
            
            let responce = JSON.JSONObject(data!)
            
            if let event = responce["event"].object {
                
            } else if let delete = responce["delete"].object {
            } else if let status = responce["delete"]["status"].object {
            } else if let direct_message = responce["delete"]["direct_message"].object {
            } else if let direct_message = responce["direct_message"].object {
            } else if let text = responce["text"].string {
                let status = TwitterStatus(responce)
                self.renderData([status], mode: .TOP, handler: {})
            }
            
//            println(responce)
        }
        let stallWarningHandler = {
            (code: String?, message: String?, percentFull: Int?) -> Void in
            
            println("code:\(code) message:\(message) percentFull:\(percentFull)")
        }
        let failure = {
            (error: NSError) -> Void in
            
            println(error)
        }
        Twitter.swifter.getUserStreamDelimited(nil,
            stallWarnings: nil,
            includeMessagesFromFollowedAccounts: nil,
            includeReplies: nil,
            track: nil,
            locations: nil,
            stringifyFriendIDs: nil,
            progress: progress,
            stallWarningHandler: stallWarningHandler,
            failure: failure)
    }
    
    func scrollBegin() {
        Static.loadDataQueue.suspended = true
        Static.mainQueue.suspended = true
    }
    
    func scrollEnd() {
        Static.loadDataQueue.suspended = false
        Static.mainQueue.suspended = false
        isTop = self.tableView.contentOffset.y == 0
        let y = self.tableView.contentOffset.y + self.tableView.bounds.size.height - self.tableView.contentInset.bottom
        let h = self.tableView.contentSize.height
        let f = h - y
        if f < TIMELINE_FOOTER_HEIGHT {
            didScrollToBottom()
        }
        for cell in self.tableView.visibleCells() as [TwitterStatusCell] {
            if let status = cell.status {
                cell.setImage(status)
            }
        }
    }
    
    func didScrollToBottom() {
        if let maxID = lastID {
            self.loadData(maxID - 1)
        }
    }
    
    func scrollToTop() {
        self.tableView.setContentOffset(CGPointZero, animated: true)
    }
    
    func heightForStatus(status: TwitterStatus, fontSize: CGFloat) -> CGFloat {
        let layout = TwitterStatusCellLayout.fromStatus(status)
        if let height = layoutHeight[layout] {
            return height + heightForText(status.text, fontSize: fontSize) + heightForImage(status)
        } else if let cell = self.layoutHeightCell[layout] {
            cell.frame = self.tableView.bounds
            cell.setText(status)
            cell.setLayout(layout)
            let totalHeight = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            let textHeight = heightForText(status.text, fontSize: fontSize)
            layoutHeight[layout] = totalHeight - textHeight
            return totalHeight + heightForImage(status)
        } else {
            assertionFailure("cellForHeight is missing.")
        }
    }
    
    func heightForText(text: NSString, fontSize: CGFloat) -> CGFloat {
        return text.boundingRectWithSize(
            CGSizeMake((self.layoutHeightCell[.Normal]?.statusLabel.frame.size.width)!, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height
    }
    
    func heightForImage(status: TwitterStatus) -> CGFloat {
//        if status.media.count > 0 {
//            println("heightForImage: \(TwitterStatusCellImagePreviewHeight * CGFloat(status.media.count))")
//        }
        return TwitterStatusCellImagePreviewHeight * CGFloat(status.media.count)
    }
    
    func loadData(maxID: Int64?) {
        if Static.loadDataQueue.operationCount > 0 {
            println("loadData busy")
            return
        }
        println("loadData addOperation: \(maxID ?? 0)")
        let op = AsyncBlockOperation({ (op: AsyncBlockOperation) in
            let always: (()-> Void) = {
                op.finish()
                self.footerIndicatorView?.stopAnimating()
            }
            let success = { (statuses: [TwitterStatus]) -> Void in
                
                // Calc cell height for the all statuses
                for status in statuses {
                    let statusID = (status.referenceStatusID ?? status.statusID).longLongValue
                    if (self.lastID == nil || statusID < self.lastID!) {
                        self.lastID = statusID
                    }
                }
                
                // render statuses
                self.renderData(statuses, mode: .BOTTOM, handler: always)
            }
            let failure = { (error: NSError) -> Void in
                println("loadData error: \(error)")
                always()
            }
            dispatch_sync(dispatch_get_main_queue(), {
                self.footerIndicatorView?.startAnimating()
                return
            })
            Twitter.getHomeTimeline(maxID?.stringValue, success: success, failure: failure)
        })
        Static.loadDataQueue.addOperation(op)
    }
    
    func renderData(statuses: [TwitterStatus], mode: RenderMode, handler: (() -> Void)?) {
        
        let fontSize = self.layoutHeightCell[.Normal]?.statusLabel.font.pointSize ?? 12.0
        var newRowHeight = mode == .OVER ? [String:CGFloat]() : self.rowHeight
        for status in statuses {
            newRowHeight[status.statusID] = self.heightForStatus(status, fontSize: fontSize)
        }
        
        let op = NSBlockOperation { () -> Void in
            
            var oldRows = self.rows
            
            var deleteIndexPaths = [NSIndexPath]()
            var totalRowsCount = mode == .OVER ? statuses.count : statuses.count + self.rows.count
            if totalRowsCount > TIMELINE_ROWS_LIMIT {
                let deleteCount = totalRowsCount - TIMELINE_ROWS_LIMIT
                let leaveCount = oldRows.count - deleteCount
                if mode == .TOP {
                    deleteIndexPaths = (leaveCount ..< oldRows.count).map { i in NSIndexPath(forRow: i, inSection: 0) }
                    oldRows = Array(oldRows[0 ..< leaveCount])
                } else {
                    deleteIndexPaths = (0 ..< deleteCount).map { i in NSIndexPath(forRow: i, inSection: 0) }
                    oldRows = Array(oldRows[deleteCount ..< oldRows.count])
                }
            }
            
            var insertIndexPaths = [NSIndexPath]()
            let newRows: [TwitterStatus] = {
                switch (mode) {
                case .TOP:
                    insertIndexPaths = (0 ..< statuses.count).map { i in NSIndexPath(forRow: i, inSection: 0) }
                    return statuses + oldRows
                case .BOTTOM:
                    insertIndexPaths = (oldRows.count ..< (oldRows.count + statuses.count)).map { i in NSIndexPath(forRow: i, inSection: 0) }
                    return oldRows + statuses
                case .OVER:
                    return statuses
                }
            }()
            
            println("renderData lastID: \(self.lastID ?? 0) insertIndexPaths: \(insertIndexPaths.count) deleteIndexPaths: \(deleteIndexPaths.count) oldRows:\(self.rows.count) nowRows: \(newRows.count)")
            
            self.rowHeight = newRowHeight
            self.rows = newRows
            
            if mode == .OVER {
                
                self.tableView.setContentOffset(CGPointZero, animated: false)
                self.tableView.reloadData()
                
            } else if mode == .BOTTOM && deleteIndexPaths.count == 0 {
                
                self.tableView.reloadData()
                
            } else if let lastCell = self.tableView.visibleCells().last as? UITableViewCell {
                
                let offset = lastCell.frame.origin.y - self.tableView.contentOffset.y;
                UIView.setAnimationsEnabled(false)
                self.tableView.beginUpdates()
                if deleteIndexPaths.count > 0 {
                    self.tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .None)
                }
                if insertIndexPaths.count > 0 {
                    self.tableView.insertRowsAtIndexPaths(insertIndexPaths, withRowAnimation: .None)
                }
                self.tableView.endUpdates()
                self.tableView.setContentOffset(CGPointMake(0, lastCell.frame.origin.y - offset), animated: false)
                UIView.setAnimationsEnabled(true)
                if self.isTop {
                    self.scrollToTop()
                }
            } else {
                self.tableView.setContentOffset(CGPointZero, animated: false)
                self.tableView.reloadData()
            }
            
            if let h = handler {
                h()
            }
        }
        Static.mainQueue.addOperation(op)
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
