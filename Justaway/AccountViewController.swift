import UIKit
import Accounts
import Social
import SwifteriOS

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    var rows:Array<AccountSettings.Account> = []
    
    override var nibName: String {
        return "AccountViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        if let accountSettings = AccountSettingsStore.load() {
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
        let url = self.rows[indexPath.row].profileImageBiggerURL
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let imageData :NSData = NSData.dataWithContentsOfURL(url, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
            dispatch_async(dispatch_get_main_queue(), {
                cell.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
                cell.imageView?.image = UIImage(data:imageData)
                cell.setNeedsLayout()
            })
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
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            self.rows.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
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
            var actionSheet =  UIAlertController(title: "Add Account", message: "Choose via", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            actionSheet.addAction(UIAlertAction(title: "via iOS", style: UIAlertActionStyle.Default, handler: { action in
                self.loadAccountFromOS()
            }))
            
            actionSheet.addAction(UIAlertAction(title: "via Justaway for iOS", style: UIAlertActionStyle.Default, handler: { action in
                self.loadAccountFromOAuth()
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            
            self.presentViewController(actionSheet, animated: true, completion: nil)
        }
    }
    
    @IBAction func right(sender: UIButton) {
        if (tableView.editing == true) {
            done()
        } else {
            edit()
        }
    }
    
    func loadAccountFromOAuth() {
        let failureHandler: ((NSError) -> Void) = {
            error in
            self.alertWithTitle("Error", message: error.localizedDescription)
        }
        let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        let url = NSURL(string: "justaway://success")
        swifter.authorizeWithCallbackURL(url, success: {
            accessToken, response in
            
            if let token = accessToken {
                self.merge([
                    AccountSettings.Account(
                        credential: SwifterCredential(accessToken: token),
                        userID: token.userID!,
                        screenName: token.screenName ?? "",
                        name: token.screenName! ?? "",
                        profileImageURL: NSURL(string: ""))
                    ])
            }
            
        }, failure: failureHandler)
    }
    
    func loadAccountFromOS() {
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
                    self.merge(
                        twitterAccounts.map({ twitterAccount in
                            AccountSettings.Account(
                                credential: SwifterCredential(account: twitterAccount as ACAccount),
                                userID: twitterAccount.valueForKeyPath("properties.user_id") as String,
                                screenName: twitterAccount.username,
                                name: twitterAccount.username,
                                profileImageURL: NSURL(string: ""))
                        })
                    )
                }
            } else {
                self.alertWithTitle("Error", message: error.localizedDescription)
            }
        }
    }
    
    func merge(accounts: Array<AccountSettings.Account>) {
        var rows = self.rows
        for account in accounts {
            var overwrite = false
            rows = rows.map({ row in
                if row.userID == account.userID {
                    overwrite = true
                    return account
                } else {
                    return row
                }
            })
            if !overwrite {
                rows.insert(account, atIndex: 0)
            }
        }
        let userIDs: Array<Int> = rows.map({ row in row.userID.toInt()! })
        let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        swifter.client.credential = rows[0].credential
        swifter.getUsersLookupWithUserIDs(userIDs, includeEntities: false, success: {
            users in
            for user in users! {
                rows = rows.map({ row in
                    if row.userID == user["id_str"].string! {
                        return AccountSettings.Account(
                            credential: row.credential,
                            userID: user["id_str"].string ?? row.userID,
                            screenName: user["screen_name"].string ?? row.screenName,
                            name: user["name"].string ?? row.name,
                            profileImageURL: NSURL(string: user["profile_image_url"].string ?? ""))
                    } else {
                        return row
                    }
                })
            }
            AccountSettingsStore.save(AccountSettings(current: 0, accounts: rows))
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.rows = rows
                self.tableView.reloadData()
            })
            }, failure: { error in })
    }
    
    func initEditing() {
        tableView.setEditing(false, animated: true)
        leftButton.setTitle("Add", forState: UIControlState.Normal)
        rightButton.setTitle("Edit", forState: UIControlState.Normal)
    }
    
    func cancel() {
        if let accountSettings = AccountSettingsStore.load() {
            self.rows = accountSettings.accounts
            self.tableView.reloadData()
        }
        initEditing()
    }
    
    func edit() {
        tableView.setEditing(true, animated: true)
        leftButton.setTitle("Cancel", forState: UIControlState.Normal)
        rightButton.setTitle("Done", forState: UIControlState.Normal)
    }
    
    func done() {
        AccountSettingsStore.save(AccountSettings(current: 0, accounts: self.rows))
        initEditing()
    }
    
}
