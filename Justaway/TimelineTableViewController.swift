import UIKit

class TimelineTableViewController: UITableViewController {
    
    var rows = [TwitterStatus]()
    var rowHeight = [String:CGFloat]()
    var minHeight = [String:CGFloat]()
    var cellForHeight: TwitterStatusCell?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        cell.setText(status)
        
        ImageLoaderClient.displayUserIcon(status.user.profileImageURL, imageView: cell.iconImageView)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let status = rows[indexPath.row]
        return rowHeight[status.statusID]!
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    // MARK: Public Methods
    
    func heightForStatus(status: TwitterStatus) -> CGFloat {
        let pattern = "normal"
        if let height = minHeight[pattern] {
            return height + heightForText(status.text, fontSize: 12.0)
        } else if let cell = cellForHeight {
            cell.frame = self.tableView.bounds
            cell.setText(status)
            cell.contentView.setNeedsLayout()
            cell.contentView.layoutIfNeeded()
            let totalHeight = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height
            let textHeight = heightForText(status.text, fontSize: 12.0)
            minHeight[pattern] = totalHeight - textHeight
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
        Twitter.getHomeTimeline { (statuses: [TwitterStatus]) -> Void in
            
            // Calc cell height for the all statuses
            for status in statuses {
                self.rowHeight[status.statusID] = self.heightForStatus(status)
            }
            
            // Set statuses
            self.rows = statuses
            
            // Show tweets
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        }
    }
    
}
