import UIKit
import Accounts
import Social
import EventBox
import TwitterAPI
import Async

class AccountViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // MARK: Types

    struct TableViewConstants {
        static let tableViewCellIdentifier = "Cell"
    }

    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }

    struct Static {
        static let instance = AccountViewController()
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

        let delay = settings == nil ? 0.3 : 0
        settings = AccountSettingsStore.get()
        initEditing()
        Async.main(after: delay) {
            self.tableView.reloadData()
        }
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

        refreshControl.addTarget(self, action: #selector(refresh), forControlEvents: UIControlEvents.ValueChanged)

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(hide))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = UISwipeGestureRecognizerDirection.Right
        tableView.addGestureRecognizer(swipe)
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: twitterAuthorizeNotification) {
            [weak self] (notification: NSNotification!) in
            guard let `self` = self else {
                return
            }
            self.refreshControl.endRefreshing()
            self.cancel()

            if (self.settings?.accounts.count ?? 0) == 0 {
                self.hide()
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings?.accounts.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(TableViewConstants.tableViewCellIdentifier, forIndexPath: indexPath) as! AccountCell // swiftlint:disable:this force_cast
        if let account = self.settings?.accounts[indexPath.row] {
            cell.account = account
            cell.setText()
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
            EventBox.post(eventAccountChanged)
            hide()
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

    @IBAction func close(sender: AnyObject) {
        hide()
    }

    @IBAction func left(sender: UIButton) {
        if tableView.editing {
            cancel()
        } else {
            AddAccountAlert.show(sender)
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
            self.view.frame = self.view.frame.offsetBy(dx: self.view.frame.size.width, dy: 0)
            }, completion: { finished in
                self.view.removeFromSuperview()
        })
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
            EventBox.post(twitterAuthorizeNotification)
        }
        tableView.reloadData()
        initEditing()
    }

    func refresh() {
        Twitter.refreshAccounts([])
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
