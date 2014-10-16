import UIKit

class TimelineTableViewController: UITableViewController {
    
    var rows = [TwitterStatus]()
    
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorInset = UIEdgeInsetsZero
        
        let nib = UINib(nibName: "TwitterStatusCell", bundle: nil)
        self.tableView.registerNib(nib, forCellReuseIdentifier: "Cell")
//        self.tableView.delegate = self
//        self.tableView.dataSource = self
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as TwitterStatusCell
        let status = rows[indexPath.row]
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        
        cell.nameLabel.text = status.user.name
        cell.screenNameLabel.text = "@" + status.user.screenName
        cell.protectedLabel.hidden = status.isProtected ? false : true
        cell.statusLabel.text = status.text
        cell.retweetCountLabel.text = status.retweetCount > 0 ? numberFormatter.stringFromNumber(status.retweetCount) : ""
        cell.favoriteCountLabel.text = status.favoriteCount > 0 ? numberFormatter.stringFromNumber(status.favoriteCount) : ""
        cell.relativeCreatedAtLabel.text = status.createdAt.relativeString
        cell.absoluteCreatedAtLabel.text = status.createdAt.absoluteString
        cell.viaLabel.text = status.via.name
        cell.imagesContainerView.hidden = true
        cell.actionedContainerView.hidden = true
        cell.createdAtBottom.constant = 5.0
        
        return cell
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//        cell.separatorInset = UIEdgeInsetsZero
//        cell.layoutMargins = UIEdgeInsetsZero
//        cell.preservesSuperviewLayoutMargins = false
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        if let settings = self.settings {
//            self.settings = AccountSettings(current: indexPath.row, accounts: settings.accounts)
//            self.tableView.reloadData()
//            AccountSettingsStore.save(self.settings!)
//        }
    }
    
    // MARK: Public Methods
    
    func loadData() {
        Twitter.getHomeTimeline { (statuses: [TwitterStatus]) -> Void in
            for status in statuses {
                println(status.user.userID)
                println(status.user.screenName)
                println(status.user.profileImageURL)
                println(status.text)
                println(status.via.name)
                println(status.createdAt.relativeString)
                println(status.createdAt.absoluteString)
            }
            self.rows = statuses
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.reloadData()
            })
        }
    }
    
}
