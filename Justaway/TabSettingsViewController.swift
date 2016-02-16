import UIKit
import Accounts
import Social
import EventBox
import TwitterAPI

class TabSettingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: Types

    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }

    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }

    struct Static {
        static let instance = TabSettingsViewController()
    }

    // MARK: Properties

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    let refreshControl = UIRefreshControl()

    var account: Account?

    override var nibName: String {
        return "TabSettingsViewController"
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

        account = AccountSettingsStore.get()?.account()
        tableView.reloadData()
        initEditing()
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
        tableView.registerNib(UINib(nibName: "TabSettingsCell", bundle: nil), forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        tableView.addSubview(refreshControl)

        refreshControl.addTarget(self, action: Selector("refresh"), forControlEvents: UIControlEvents.ValueChanged)

        let swipe = UISwipeGestureRecognizer(target: self, action: "hide")
        swipe.numberOfTouchesRequired = 1
        swipe.direction = UISwipeGestureRecognizerDirection.Right
        tableView.addGestureRecognizer(swipe)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: "addTab") {
            [weak self] (notification: NSNotification!) in
            guard let `self` = self else {
                return
            }
            guard let tab = notification.object as? Tab else {
                return
            }
            guard let account = self.account else {
                return
            }
            let newAccount = Account(account: account, tabs: account.tabs + [tab])
            self.account = newAccount
            self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: newAccount.tabs.count - 1, inSection: 0)], withRowAnimation: .Automatic)
            if let settings = AccountSettingsStore.get() {
                let accounts = settings.accounts.map({ $0.userID == newAccount.userID ? newAccount : $0 })
                AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                EventBox.post(eventTabChanged)
            }
        }
        EventBox.onMainThread(self, name: "setSavedSearchTab") {
            [weak self] (notification: NSNotification!) in
            guard let `self` = self else {
                return
            }
            guard var addTabs = notification.object as? [Tab] else {
                return
            }
            guard let account = self.account else {
                return
            }
            var keepTabs = [Tab]()
            for tab in account.tabs {
                if tab.type != .Searches {
                    keepTabs.append(tab)
                } else if let index = addTabs.indexOf({ $0.keyword == tab.keyword }) {
                    keepTabs.append(tab)
                    addTabs.removeAtIndex(index)
                }
            }
            let newAccount = Account(account: account, tabs: keepTabs + addTabs)
            self.account = newAccount
            self.tableView.reloadData()
            if let settings = AccountSettingsStore.get() {
                let accounts = settings.accounts.map({ $0.userID == newAccount.userID ? newAccount : $0 })
                AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                EventBox.post(eventTabChanged)
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account?.tabs.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as! TabSettingsCell
        if let tab = self.account?.tabs[indexPath.row] {
            switch tab.type {
            case .HomeTimline:
                cell.nameLabel.text = "Home"
                cell.iconLabel.text = "家"
            case .UserTimline:
                cell.nameLabel.text = tab.user.name + " / @" + tab.user.screenName
                cell.iconLabel.text = "人"
            case .Notifications:
                cell.nameLabel.text = "Notifications"
                cell.iconLabel.text = "鐘"
            case .Favorites:
                cell.nameLabel.text = "Likes"
                cell.iconLabel.text = "好"
            case .Searches:
                cell.nameLabel.text = tab.keyword
                cell.iconLabel.text = "探"
            }
        }
        return cell
    }

    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }

    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        guard let account = account else {
            return
        }
        if destinationIndexPath.row >= account.tabs.count {
            return
        }
        var tabs = account.tabs
        tabs.insert(tabs.removeAtIndex(sourceIndexPath.row), atIndex: destinationIndexPath.row)
        self.account = Account(account: account, tabs: tabs)
    }

    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        if let settings = self.settings {
//            self.settings = AccountSettings(current: indexPath.row, accounts: settings.accounts)
//            self.tableView.reloadData()
//            AccountSettingsStore.save(self.settings!)
//            EventBox.post(eventAccountChanged)
//            hide()
//        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle != .Delete {
            return
        }
        guard let account = account else {
            return
        }
        var tabs = account.tabs
        tabs.removeAtIndex(indexPath.row)
        self.account = Account(account: account, tabs: tabs)
        if tabs.count > 0 {
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        } else {
            tableView.reloadData()
        }
    }

    // MARK: - Actions

    @IBAction func close(sender: AnyObject) {
        hide()
    }

    @IBAction func left(sender: UIButton) {
        if tableView.editing {
            cancel()
        } else {
            if let account = account {
                AddTabAlert.show(sender, tabs: account.tabs)
            }
        }
    }

    @IBAction func right(sender: UIButton) {
        if tableView.editing {
            done()
        } else {
            edit()
        }
    }

    func hide() {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.view.frame = CGRect.init(
                x: self.view.frame.size.width,
                y: self.view.frame.origin.y,
                width: self.view.frame.size.width,
                height: self.view.frame.size.height)
            }, completion: { finished in
                self.view.removeFromSuperview()
        })
    }

    func initEditing() {
        tableView.setEditing(false, animated: false)
        leftButton.setTitle("Add", forState: UIControlState.Normal)
        rightButton.setTitle("Edit", forState: UIControlState.Normal)
        rightButton.hidden = account == nil
    }

    func cancel() {
        account = AccountSettingsStore.get()?.account()
        tableView.reloadData()
        initEditing()
    }

    func edit() {
        tableView.setEditing(true, animated: true)
        leftButton.setTitle("Cancel", forState: UIControlState.Normal)
        rightButton.setTitle("Done", forState: UIControlState.Normal)
    }

    func done() {
        if let account = account {
            if let settings = AccountSettingsStore.get() {
                let accounts = settings.accounts.map({ $0.userID == account.userID ? account : $0 })
                AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                EventBox.post(eventTabChanged)
            }
        }
        tableView.reloadData()
        initEditing()
    }

    func refresh() {
//        Twitter.refreshAccounts([])
    }

    class func show() {
        if let vc = ViewTools.frontViewController() {
            Static.instance.view.hidden = true
            vc.view.addSubview(Static.instance.view)
            Static.instance.view.frame = CGRect.init(x: vc.view.frame.width, y: 20, width: vc.view.frame.width, height: vc.view.frame.height - 20)
            Static.instance.view.hidden = false

            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
                Static.instance.view.frame = CGRect.init(x: 0,
                    y: 20,
                    width: vc.view.frame.size.width,
                    height: vc.view.frame.size.height - 20)
                }) { (finished) -> Void in
            }
        }
    }
}
