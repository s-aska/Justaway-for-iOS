import UIKit
import Accounts
import Social
import SwifteriOS
import EventBox

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // MARK: Types
    
    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }
    
    // MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    let refreshControl = UIRefreshControl()
    
    var settings: AccountSettings?
    
    override var nibName: String {
        return "AccountViewController"
    }
    
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
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerNib(UINib(nibName: "AccountCell", bundle: nil), forCellReuseIdentifier: "Account")
        tableView.addSubview(refreshControl)
        
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        
        settings = AccountSettingsStore.get()
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: TwitterAuthorizeNotification) {
            (notification: NSNotification!) in
            
            self.refreshControl.endRefreshing()
            self.cancel()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.accounts.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Account", forIndexPath: indexPath) as! AccountCell
        if let account = self.settings?.accounts[indexPath.row] {
            cell.displayNameLabel.text = account.name
            cell.screenNameLabel.text = account.screenName
            cell.clientNameLabel.text = account.credential.accessToken != nil ? "Justaway" : "iOS"
            ImageLoaderClient.displayUserIcon(account.profileImageBiggerURL, imageView: cell.iconImageView)
        }
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
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let settings = self.settings {
            self.settings = AccountSettings(current: indexPath.row, accounts: settings.accounts)
            self.tableView.reloadData()
            AccountSettingsStore.save(self.settings!)
            EventBox.post("AccountChange")
        }
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
        self.view.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
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
            self.view.window?.rootViewController?.presentViewController(actionSheet, animated: true, completion: nil)
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
        Twitter.addOAuthAccount()
    }
    
    func addAccounByAcAccount() {
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        
        // Prompt the user for permission to their twitter account stored in the phone's settings
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                
                if twitterAccounts.count == 0 {
                    self.alertWithTitle("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                } else {
                    self.addAccouns(
                        twitterAccounts.map({ (twitterAccount: ACAccount) in
                            Account(
                                credential: SwifterCredential(account: twitterAccount),
                                userID: twitterAccount.valueForKeyPath("properties.user_id") as! String,
                                screenName: twitterAccount.username,
                                name: twitterAccount.username,
                                profileImageURL: NSURL(string: "")!)
                        })
                    )
                }
            } else {
                self.alertWithTitle("Error", message: error.localizedDescription)
            }
        }
    }
    
    func addAccouns(accounts: [Account]) {
        Twitter.refreshAccounts(accounts)
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
    
    func refresh() {
        Twitter.refreshAccounts([])
    }
}
