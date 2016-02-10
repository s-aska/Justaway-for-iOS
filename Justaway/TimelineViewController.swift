import UIKit
import EventBox

class TimelineViewController: UIViewController, UIScrollViewDelegate {

    // MARK: Properties

    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var streamingButton: StreamingButton!
    @IBOutlet weak var tabScrollView: UIScrollView!
    @IBOutlet weak var tabWrapperView: UIView!
    @IBOutlet weak var tabCurrentMaskLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabWrapperWidthConstraint: NSLayoutConstraint!

    var swipeGestureRecognizer: UISwipeGestureRecognizer?
    var settingsViewController: SettingsViewController!
    var sideMenuViewController: SideMenuViewController!
    var tableViewControllers = [TimelineTableViewController]()
    var tabButtons = [MenuButton]()
    var setupView = false
    var userID = ""
    var currentPage = 0

    struct Static {
        private static let connectionQueue = NSOperationQueue().serial()
    }

    override var nibName: String {
        return "TimelineViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !setupView {
            setupView = true
            configureView()

            // ViewDidDisappear is performed When you view the ProfileViewController.
            configureEvent()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        settingsViewController = SettingsViewController()
        sideMenuViewController = SideMenuViewController()

        sideMenuViewController.settingsViewController = settingsViewController

        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)

        if let account = AccountSettingsStore.get() {
            userID = account.account().userID
        }

        let swipe = UISwipeGestureRecognizer(target: self, action: "showSideMenu")
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .Right
        scrollView.panGestureRecognizer.requireGestureRecognizerToFail(swipe)
        scrollView.addGestureRecognizer(swipe)
        swipeGestureRecognizer = swipe

        configureTimelineView()
    }

    // swiftlint:disable:next cyclomatic_complexity
    func configureTimelineView() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }

        currentPage = min(currentPage, account.tabs.count - 1)

        var vcCache = [String: TimelineTableViewController]()
        for tableViewController in tableViewControllers {
            switch tableViewController {
            case let vc as HomeTimelineTableViewController:
                vcCache["HomeTimelineTableViewController"] = vc
            case let vc as UserTimelineTableViewController:
                if let userID = vc.userID {
                    vcCache["UserTimelineTableViewController-" + userID] = vc
                }
            case let vc as SearchesTableViewController:
                if let keyword = vc.keyword {
                    vcCache["SearchesTableViewController-" + keyword] = vc
                }
            case let vc as NotificationsViewController:
                vcCache["NotificationsViewController"] = vc
            case let vc as FavoritesTableViewController:
                vcCache["FavoritesTableViewController"] = vc
            default:
                break
            }
        }
        tableViewControllers.removeAll()

        for view in tabWrapperView.subviews {
            if view.tag >= 0 {
                view.removeFromSuperview()
            }
        }

        let size = scrollWrapperView.frame.size
        let contentView = UIView(frame: CGRect.init(x: 0, y: 0, width: size.width * CGFloat(account.tabs.count), height: size.height))
        tabWrapperWidthConstraint.constant = 58 * CGFloat(account.tabs.count)

        for (i, tab) in account.tabs.enumerate() {
            let vc: TimelineTableViewController
            let icon: String
            switch tab.type {
            case .HomeTimline:
                vc = vcCache["HomeTimelineTableViewController"] ?? HomeTimelineTableViewController()
                icon = "家"
            case .UserTimline:
                let uvc = vcCache["UserTimelineTableViewController-" + tab.user.userID] as? UserTimelineTableViewController ?? UserTimelineTableViewController()
                uvc.userID = tab.user.userID
                vc = uvc
                icon = "人"
            case .Notifications:
                vc = vcCache["NotificationsViewController"] ?? NotificationsViewController()
                icon = "鐘"
            case .Favorites:
                vc = vcCache["FavoritesTableViewController"] ?? FavoritesTableViewController()
                icon = "好"
            case .Searches:
                let keyword = tab.keyword
                let svc = vcCache["SearchesTableViewController-" + keyword] as? SearchesTableViewController ?? SearchesTableViewController()
                svc.keyword = keyword
                vc = svc
                icon = "探"
            }
            vc.tableView.contentInset = UIEdgeInsetsMake(60, 0, 0, 0)
            vc.view.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
            let view = UIView(frame: CGRect.init(x: size.width * CGFloat(i), y: 0, width: size.width, height: size.height))
            view.addSubview(vc.view)
            contentView.addSubview(view)
            tableViewControllers.append(vc)

            if let favoritesTableViewController = vc as? FavoritesTableViewController {
                favoritesTableViewController.userID = userID
            }

            if let statusTableViewController = vc as? StatusTableViewController {
                statusTableViewController.adapter.scrollEnd(vc.tableView)
            }

            let button = createMenuButton(i, icon: icon)
            tabWrapperView.addSubview(button)
            tabButtons.append(button)

            if let statusVc = vc as? StatusTableViewController {
                let page = i
                statusVc.adapter.renderDataCallback = { (statuses: [TwitterStatus], mode: TwitterStatusAdapter.RenderMode) in
                    if statuses.count > 0 && mode == .HEADER {
                        NSLog("page:\(page) count:\(statuses.count)")
                        self.tabButtons[page].selected = true
                    }
                }
            }
        }

        tabScrollView.contentSize = tabWrapperView.frame.size

        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        scrollView.contentOffset = CGPoint.init(x: scrollView.frame.size.width * CGFloat(currentPage), y: 0)

        highlightUpdate(currentPage)
    }

    func createMenuButton(index: Int, icon: String) -> MenuButton {
        let button = MenuButton(type: UIButtonType.System)
        button.tag = index
        button.tintColor = UIColor.clearColor()
        button.titleLabel?.font = UIFont(name: "fontello", size: 20.0)
        button.frame = CGRect.init(x: 58 * CGFloat(index), y: 0, width: 58, height: 50)
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        button.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
        button.setTitle(icon, forState: UIControlState.Normal)
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabButton:"))
        let longPress = UILongPressGestureRecognizer(target: self, action: "refresh:")
        longPress.minimumPressDuration = 2.0
        button.addGestureRecognizer(longPress)
        return button
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventTabChanged, handler: { _ in
            self.configureTimelineView()
        })

        EventBox.onMainThread(self, name: twitterAuthorizeNotification, handler: { _ in
            self.reset()
        })

        EventBox.onMainThread(self, name: eventAccountChanged, handler: { _ in
            self.reset()
            self.settingsViewController.hide()
        })

        configureCreateStatusEvent()

        configureDestroyStatusEvent()

        configureStreamingEvent()

        EventBox.onMainThread(self, name: "timelineScrollToTop", handler: { _ in
            if self.tableViewControllers.count <= self.currentPage {
                return
            }
            if let vc = self.tableViewControllers[self.currentPage] as? StatusTableViewController {
                if vc.adapter.isTop {
                    self.tabButtons[self.currentPage].selected = false
                }
            }
        })

        EventBox.onBackgroundThread(self, name: "applicationDidEnterBackground") { (n) -> Void in
            for tableViewController in self.tableViewControllers {
                switch tableViewController {
                case let vc as StatusTableViewController:
                    vc.saveCache()
                default:
                    break
                }
            }
        }
    }

    func configureCreateStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.rawValue, sender: nil) { n in
            guard let status = n.object as? TwitterStatus else {
                return
            }
            var page = 0
            for tableViewController in self.tableViewControllers {
                switch tableViewController {
                case let vc as StatusTableViewController:
                    if vc.accept(status) {
                        vc.renderData([status], mode: .TOP, handler: {})
                        let actionedByUserID = status.actionedBy?.userID ?? ""
                        let actionedByMe = AccountSettingsStore.get()?.isMe(actionedByUserID) ?? false
                        if !actionedByMe {
                            if self.currentPage != page {
                                self.tabButtons[page].selected = true
                            } else {
                                let buttonIndex = page
                                let operation = MainBlockOperation { (operation) -> Void in
                                    if !vc.adapter.isTop {
                                        self.tabButtons[buttonIndex].selected = true
                                    }
                                    operation.finish()
                                }
                                vc.adapter.mainQueue.addOperation(operation)
                            }
                        }
                        vc.saveCacheSchedule()
                    }
                default:
                    break
                }
                page++
            }
        }
    }

    func configureDestroyStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.DestroyStatus.rawValue, sender: nil) { n in
            guard let statusID = n.object as? String else {
                return
            }
            var page = 0
            for tableViewController in self.tableViewControllers {
                switch tableViewController {
                case let vc as StatusTableViewController:
                    vc.eraseData(statusID, handler: {})
                default:
                    break
                }
                page++
            }
        }
    }

    func configureStreamingEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.StreamingStatusChanged.rawValue) { _ in
            self.sideMenuViewController.updateStreamingButtonTitle()
        }
    }

    func toggleStreaming() {

    }

    func reset() {
        if let account = AccountSettingsStore.get() {

            // other account
            if userID != account.account().userID {
                userID = account.account().userID
                for tableViewController in self.tableViewControllers {
                    switch tableViewController {
                    case let vc as StatusTableViewController:
                        vc.refresh()
                    default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let page = Int((scrollView.contentOffset.x + (scrollWrapperView.frame.size.width / 2)) / scrollWrapperView.frame.size.width)
        if currentPage != page {
            currentPage = page
            self.highlightUpdate(page)
        }

    }

    // MARK: - Actions

    func showSideMenu() {
        if let account = AccountSettingsStore.get()?.account() {
            sideMenuViewController.show(account)
        }
    }

    func highlightUpdate(page: Int) {

        swipeGestureRecognizer?.enabled = page == 0

        tabCurrentMaskLeftConstraint.constant = CGFloat(page * 58)

        if let vc = tableViewControllers[currentPage] as? StatusTableViewController {
            if vc.adapter.isTop {
                tabButtons[currentPage].selected = false
            }
        }
    }

    func refresh(sender: UILongPressGestureRecognizer) {
        if sender.state != .Began {
            return
        }
        tableViewControllers[currentPage].refresh()
    }

    func tabButton(sender: UITapGestureRecognizer) {
        if let page = sender.view?.tag {
            if currentPage == page {
                if let vc = tableViewControllers[page] as? StatusTableViewController {
                    vc.adapter.scrollToTop(vc.tableView)
                }
                tabButtons[page].selected = false
            } else {
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.frame.size.width * CGFloat(page), y: 0)
                }, completion: { (flag) -> Void in
                    self.currentPage = page
                    self.highlightUpdate(page)
                })
            }
        }
    }

    @IBAction func openSidemenu(sender: AnyObject) {
        if let account = AccountSettingsStore.get()?.account() {
            sideMenuViewController.show(account)
        }
    }

    @IBAction func streamingSwitch(sender: UIButton) {
        StreamingAlert.show(sender)
    }

    @IBAction func showEditor(sender: UIButton) {
        EditorViewController.show()
    }

    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }

    @IBAction func showPocketCover(sender: UIButton) {
        PocketCoverViewController.show()
    }

}
