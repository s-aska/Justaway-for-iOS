import UIKit
import Accounts
import Social
import EventBox
import TwitterAPI

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
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerNib(UINib(nibName: "AccountCell", bundle: nil), forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        tableView.addSubview(refreshControl)
        
        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)
        
        settings = AccountSettingsStore.get()
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: TwitterAuthorizeNotification) {
            [weak self] (notification: NSNotification!) in
            guard let `self` = self else {
                return
            }
            self.refreshControl.endRefreshing()
            self.cancel()
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.accounts.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as! AccountCell
        if let account = self.settings?.accounts[indexPath.row] {
            cell.displayNameLabel.text = account.name
            cell.screenNameLabel.text = account.screenName
            cell.clientNameLabel.text = account.client as? OAuthClient != nil ? "Justaway" : "iOS"
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
            EventBox.post(EventAccountChanged)
        }
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let settings = self.settings {
                var accounts = settings.accounts
                let current =
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
    
    @IBAction func left(sender: UIButton) {
        if (tableView.editing == true) {
            cancel()
        } else {
            AddAccountAlert.show(sender)
        }
    }
    
    @IBAction func right(sender: UIButton) {
        if (tableView.editing == true) {
            done()
        } else {
            edit()
        }
    }
    
    func initEditing() {
        tableView.setEditing(false, animated: false)
        leftButton.setTitle("Add", forState: UIControlState.Normal)
        rightButton.setTitle("Edit", forState: UIControlState.Normal)
        rightButton.hidden = self.settings == nil
    }
    
    func cancel() {
        settings = AccountSettingsStore.get()
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
