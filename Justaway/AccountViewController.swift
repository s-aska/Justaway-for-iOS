import UIKit
import Accounts
import Social

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var rows:Array<Account> = []
    
    override var nibName: String {
        return "AccountViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if let accountSettings = AccountService.load() {
            rows = accountSettings.accounts
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.accessoryType = UITableViewCellAccessoryType.Checkmark
        cell.textLabel?.text = self.rows[indexPath.row].name
        cell.detailTextLabel?.text = self.rows[indexPath.row].screenName
        let url = self.rows[indexPath.row].profileImageBiggerURL()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let imageData :NSData = NSData.dataWithContentsOfURL(url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
            dispatch_async(dispatch_get_main_queue(), {
                cell.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                cell.imageView?.image = UIImage(data:imageData)
                cell.setNeedsLayout()
            })
            NSLog("load %@", url)
        })
        return cell
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alert = UIAlertView(title: "alertTitle", message: "selected cell index is \(indexPath.row)", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    // MARK: - Actions
    
    func alertWithTitle(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    @IBAction func left(sender: UIButton) {
        if (tableView.editing == true) {
            cancel()
        } else {
            let accountStore = ACAccountStore()
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            // Prompt the user for permission to their twitter account stored in the phone's settings
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
                granted, error in
                
                if granted {
                    let twitterAccounts = accountStore.accountsWithAccountType(accountType)
                    
                    if twitterAccounts?.count == 0 {
                        self.alertWithTitle("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                    } else {
                        let idMap = NSMutableDictionary()
                        let ids :Array<String> = twitterAccounts.map({
                            twitterAccount in
                            let id = twitterAccount.valueForKeyPath("properties.user_id") as String
                            idMap.setValue(twitterAccount.identifier, forKey: id)
                            return id
                        })
                        let url = NSURL(string: "https://api.twitter.com/1.1/users/lookup.json")
                        let params = ["user_id": ids]
                        let req = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: params)
                        req.account = twitterAccounts[0] as ACAccount
                        req.performRequestWithHandler({
                            (data :NSData!, res :NSHTTPURLResponse!, error :NSError!) -> Void in
                            NSLog("%@", NSString(data: data, encoding :NSUTF8StringEncoding))
                            let users = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSArray
                            self.rows = (users as [NSDictionary]).map({
                                (user: NSDictionary) in
                                let token = idMap.valueForKey(user["id_str"] as String) as String
                                return Account(accessToken: token,
                                    userID: user["id_str"] as String,
                                    screenName: user["screen_name"] as String,
                                    name: user["name"] as String,
                                    profileImageURL: NSURL(string: user["profile_image_url"] as String),
                                    iOS: true)
                            })
                            AccountService.save(AccountSettings(current: 0, accounts: self.rows))
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                self.tableView.reloadData()
                            })
                        })
                    }
                } else {
                    self.alertWithTitle("Error", message: error.localizedDescription)
                }
            }
            
        }
    }
    
    @IBAction func right(sender: UIButton) {
        if (tableView.editing == true) {
            done()
        } else {
            edit()
        }
    }
    
    func cancel() {
        tableView.setEditing(false, animated: true)
        leftButton.setTitle("Add", forState: UIControlState.Normal)
        rightButton.setTitle("Edit", forState: UIControlState.Normal)
    }
    
    func edit() {
        tableView.setEditing(true, animated: true)
        leftButton.setTitle("Cancel", forState: UIControlState.Normal)
        rightButton.setTitle("Done", forState: UIControlState.Normal)
    }
    
    func done() {
        cancel()
    }
    
}
