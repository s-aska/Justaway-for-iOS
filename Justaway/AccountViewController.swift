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
    
    var settings: AccountSettings?
    
    override var nibName: String {
        return "AccountViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        self.settings = AccountSettingsStore.get()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.accounts.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        cell.accessoryType = self.settings?.current == indexPath.row ? .Checkmark : UITableViewCellAccessoryType.None
        cell.textLabel?.text = self.settings?.accounts[indexPath.row].name
        cell.detailTextLabel?.text = self.settings?.accounts[indexPath.row].screenName
        let url = self.settings?.accounts[indexPath.row].profileImageBiggerURL
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let imageData :NSData = NSData.dataWithContentsOfURL(url!, options: NSDataReadingOptions.DataReadingMappedIfSafe, error: nil)
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
        if let settings = self.settings {
            if destinationIndexPath.row < settings.accounts.count {
                var accounts = settings.accounts
                accounts.insert(accounts.removeAtIndex(sourceIndexPath.row), atIndex: destinationIndexPath.row)
                let current =
                    settings.current == sourceIndexPath.row ? destinationIndexPath.row :
                    settings.current == destinationIndexPath.row ? sourceIndexPath.row :
                    settings.current
                NSLog("moveRowAtIndexPath current:%i", current)
                self.settings = AccountSettings(current: current, accounts: accounts)
            }
        }
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let alert = UIAlertView(title: "alertTitle", message: "selected cell index is \(indexPath.row)", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let settings = self.settings {
                var accounts = settings.accounts
                var current =
                    indexPath.row == settings.current ? 0 :
                    indexPath.row < settings.current ? settings.current - 1 :
                    settings.current
                accounts.removeAtIndex(indexPath.row)
                NSLog("commitEditingStyle current:%i", current)
                if accounts.count > 0 {
                    self.settings = AccountSettings(current: current, accounts: accounts)
                } else {
                    self.settings = nil
                }
                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            }
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
                self.addAccounByAcAccount()
            }))
            actionSheet.addAction(UIAlertAction(title: "via Justaway for iOS", style: UIAlertActionStyle.Default, handler: { action in
                self.addAccounByOAuth()
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
    
    func addAccounByOAuth() {
        let failureHandler: ((NSError) -> Void) = {
            error in
            self.alertWithTitle("Error", message: error.localizedDescription)
        }
        let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        let url = NSURL(string: "justaway://success")
        swifter.authorizeWithCallbackURL(url, success: {
            accessToken, response in
            
            if let token = accessToken {
                self.addAccouns([
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
    
    func addAccounByAcAccount() {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        // Prompt the user for permission to their twitter account stored in the phone's settings
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType)
                
                if twitterAccounts.count == 0 {
                    self.alertWithTitle("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                } else {
                    self.addAccouns(
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
    
    func addAccouns(accounts: Array<AccountSettings.Account>) {
        Twitter.refreshAccounts(accounts, successHandler: { accounts in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.cancel()
            })
        })
    }
    
    func initEditing() {
        tableView.setEditing(false, animated: false)
        leftButton.setTitle("Add", forState: UIControlState.Normal)
        rightButton.setTitle("Edit", forState: UIControlState.Normal)
        rightButton.hidden = self.settings == nil
    }
    
    func cancel() {
        self.settings = AccountSettingsStore.get()
        tableView.reloadData()
        initEditing()
    }
    
    func edit() {
        tableView.setEditing(true, animated: true)
        leftButton.setTitle("Cancel", forState: UIControlState.Normal)
        rightButton.setTitle("Done", forState: UIControlState.Normal)
    }
    
    func done() {
        if let settings = self.settings {
            AccountSettingsStore.save(settings)
        } else {
            AccountSettingsStore.clear()
        }
        tableView.reloadData()
        initEditing()
    }
    
}
