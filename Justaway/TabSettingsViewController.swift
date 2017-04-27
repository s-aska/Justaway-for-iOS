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
        static let delay: TimeInterval = 0
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()

        account = AccountSettingsStore.get()?.account()
        tableView.reloadData()
        initEditing()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "TabSettingsCell", bundle: nil), forCellReuseIdentifier: TableViewConstants.tableViewCellIdentifier)
        tableView.addSubview(refreshControl)

        refreshControl.addTarget(self, action: #selector(TabSettingsViewController.refresh), for: UIControlEvents.valueChanged)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(TabSettingsViewController.hide))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = UISwipeGestureRecognizerDirection.right
        tableView.addGestureRecognizer(swipe)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: Notification.Name(rawValue: "addTab")) {
            [weak self] (notification: Notification!) in
            guard let `self` = self else {
                return
            }
            guard let tab = notification.object as? Tab else {
                return
            }
            guard let userID = self.account?.userID else {
                return
            }
            guard let account = AccountSettingsStore.get()?.find(userID) else {
                return
            }
            let newAccount = Account(account: account, tabs: account.tabs + [tab])
            self.account = newAccount
            self.tableView.insertRows(at: [IndexPath(row: newAccount.tabs.count - 1, section: 0)], with: .automatic)
            if let settings = AccountSettingsStore.get() {
                let accounts = settings.accounts.map({ $0.userID == newAccount.userID ? newAccount : $0 })
                AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                EventBox.post(eventTabChanged)
            }
        }
        EventBox.onMainThread(self, name: Notification.Name(rawValue: "setSavedSearchTab")) {
            [weak self] (notification: Notification!) in
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
                } else if let index = addTabs.index(where: { $0.keyword == tab.keyword }) {
                    keepTabs.append(tab)
                    addTabs.remove(at: index)
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
        EventBox.onMainThread(self, name: Notification.Name(rawValue: "setListsTab")) {
            [weak self] (notification: Notification!) in
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
                if tab.type != .Lists {
                    keepTabs.append(tab)
                } else if let index = addTabs.index(where: { $0.list.id == tab.list.id }) {
                    keepTabs.append(tab)
                    addTabs.remove(at: index)
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return account?.tabs.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewConstants.tableViewCellIdentifier, for: indexPath) as! TabSettingsCell
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
            case .Mentions:
                cell.nameLabel.text = "Mentions"
                cell.iconLabel.text = "@"
            case .Favorites:
                cell.nameLabel.text = "Likes"
                cell.iconLabel.text = "好"
            case .Searches:
                cell.nameLabel.text = tab.keyword
                cell.iconLabel.text = "探"
            case .Lists:
                cell.nameLabel.text = tab.list.name
                cell.iconLabel.text = "欄"
            case .Messages:
                cell.nameLabel.text = "Messages"
                cell.iconLabel.text = "文"
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard let account = account else {
            return
        }
        if destinationIndexPath.row >= account.tabs.count {
            return
        }
        var tabs = account.tabs
        tabs.insert(tabs.remove(at: sourceIndexPath.row), at: destinationIndexPath.row)
        self.account = Account(account: account, tabs: tabs)
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if let settings = self.settings {
//            self.settings = AccountSettings(current: indexPath.row, accounts: settings.accounts)
//            self.tableView.reloadData()
//            AccountSettingsStore.save(self.settings!)
//            EventBox.post(eventAccountChanged)
//            hide()
//        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete {
            return
        }
        guard let account = account else {
            return
        }
        var tabs = account.tabs
        tabs.remove(at: indexPath.row)
        self.account = Account(account: account, tabs: tabs)
        if tabs.count > 0 {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        } else {
            tableView.reloadData()
        }
    }

    // MARK: - Actions

    @IBAction func close(_ sender: AnyObject) {
        hide()
    }

    @IBAction func left(_ sender: UIButton) {
        if tableView.isEditing {
            cancel()
        } else {
            if let account = account {
                AddTabAlert.show(sender, account: account)
            }
        }
    }

    @IBAction func right(_ sender: UIButton) {
        if tableView.isEditing {
            done()
        } else {
            edit()
        }
    }

    func hide() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.view.frame = self.view.frame.offsetBy(dx: self.view.frame.size.width, dy: 0)
            }, completion: { finished in
                self.view.removeFromSuperview()
        })
    }

    func initEditing() {
        tableView.setEditing(false, animated: false)
        leftButton.setTitle("Add", for: UIControlState())
        rightButton.setTitle("Edit", for: UIControlState())
        rightButton.isHidden = account == nil
    }

    func cancel() {
        account = AccountSettingsStore.get()?.account()
        tableView.reloadData()
        initEditing()
    }

    func edit() {
        tableView.setEditing(true, animated: true)
        leftButton.setTitle("Cancel", for: UIControlState())
        rightButton.setTitle("Done", for: UIControlState())
    }

    func done() {
        if let account = account {
            if let settings = AccountSettingsStore.get() {
                let accounts = settings.accounts.map({ $0.userID == account.userID ? account : $0 })
                _ = AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
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
            Static.instance.view.isHidden = true
            vc.view.addSubview(Static.instance.view)
            Static.instance.view.frame = CGRect.init(x: vc.view.frame.width, y: 20, width: vc.view.frame.width, height: vc.view.frame.height - 20)
            Static.instance.view.isHidden = false

            UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: { () -> Void in
                Static.instance.view.frame = CGRect.init(x: 0,
                    y: 20,
                    width: vc.view.frame.size.width,
                    height: vc.view.frame.size.height - 20)
                }) { (finished) -> Void in
            }
        }
    }
}
