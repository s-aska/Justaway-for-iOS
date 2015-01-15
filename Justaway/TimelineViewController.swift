import UIKit
import SwifteriOS
import EventBox

class TimelineViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var streamingStatusLabel: UILabel!
    @IBOutlet weak var streamingView: UIView!
    @IBOutlet weak var streamingIcon: UILabel!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    var tableViewControllers = [TimelineTableViewController]()
    
    struct Static {
        private static let connectionQueue = NSOperationQueue().serial()
    }
    
    override var nibName: String {
        return "TimelineViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureView()
        configureEvent()
    }
    
    deinit {
        EventBox.off(self)
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
    
    // MARK: - Configuration
    
    func configureView() {
        editorViewController = EditorViewController()
        editorViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(self.view, view: editorViewController.view)
        
        settingsViewController = SettingsViewController()
        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)
        
        if let account = AccountSettingsStore.get() {
            ImageLoaderClient.displayTitleIcon(account.account().profileImageURL, imageView: iconImageView)
        }
        
        var size = scrollWrapperView.frame.size
        println(size.width)
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
        
        for i in 0 ... 3 {
            let vc = TimelineTableViewController()
            vc.view.frame = CGRectMake(0, 0, size.width, size.height)
            let view = UIView(frame: CGRectMake(size.width * CGFloat(i), 0, size.width, size.height))
            view.addSubview(vc.view)
            contentView.addSubview(view)
            tableViewControllers.append(vc)
        }
        
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.pagingEnabled = true
        
        var longPress = UILongPressGestureRecognizer(target: self, action: "refresh:")
        longPress.minimumPressDuration = 2.0;
        homeButton.addGestureRecognizer(longPress)
        
        streamingView.userInteractionEnabled = true
        var gesture = UITapGestureRecognizer(target: self, action: "streamingSwitch:")
        gesture.numberOfTapsRequired = 1
        streamingView.addGestureRecognizer(gesture)
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.rawValue, sender: nil) { n in
            let status = n.object as TwitterStatus
            self.tableViewControllers.first?.renderData([status], mode: .TOP, handler: {})
        }
        
        EventBox.onMainThread(self, name: "streamingStatusChange") { _ in
            switch Twitter.connectionStatus {
            case .CONNECTED:
                self.streamingStatusLabel.text = "connected"
                self.streamingIcon.textColor = ThemeController.currentTheme.streamingConnected()
            case .CONNECTING:
                self.streamingStatusLabel.text = "connecting..."
                self.streamingIcon.textColor = ThemeController.currentTheme.bodyTextColor()
            case .DISCONNECTED:
                self.streamingStatusLabel.text = "disconnected"
                if Twitter.enableStreaming {
                    self.streamingIcon.textColor = ThemeController.currentTheme.streamingError()
                } else {
                    self.streamingIcon.textColor = ThemeController.currentTheme.bodyTextColor()
                }
            case .DISCONNECTING:
                self.streamingStatusLabel.text = "disconnecting..."
                self.streamingIcon.textColor = ThemeController.currentTheme.bodyTextColor()
            }
        }
    }
    
    func toggleStreaming() {
        
    }
    
    // MARK: - Actions
    
    func refresh(sender: AnyObject) {
        tableViewControllers.first?.loadData(nil)
    }
    
    func streamingSwitch(sender: AnyObject) {
        if Twitter.connectionStatus == .DISCONNECTED {
            Twitter.startStreamingAndEnable()
        } else if Twitter.connectionStatus == .CONNECTED {
            Twitter.stopStreamingAndDisable()
        }
        
    }
    
    @IBAction func signInButtonClick(sender: UIButton) {
        
    }
    
    @IBAction func homeButton(sender: UIButton) {
        tableViewControllers.first?.scrollToTop()
    }
    
    @IBAction func showEditor(sender: UIButton) {
        editorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
    
}
