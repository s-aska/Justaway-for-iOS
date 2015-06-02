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
    @IBOutlet weak var streamingButton: StreamingButton!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    var tableViewControllers = [TimelineTableViewController]()
    var imageViewController: ImageViewController?
    var setupView = false
    var userID = ""
    
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
        }
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
        editorViewController = EditorViewController()
        editorViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(self.view, view: editorViewController.view)
        
        settingsViewController = SettingsViewController()
        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)
        
        if let account = AccountSettingsStore.get() {
            userID = account.account().userID
            ImageLoaderClient.displayTitleIcon(account.account().profileImageURL, imageView: iconImageView)
        }
        
        var size = scrollWrapperView.frame.size
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
        
        for i in 0 ... 1 {
            let vc: TimelineTableViewController = i == 0 ? HomeTimelineTableViewController() : NotificationsViewController()
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
        EventBox.onMainThread(self, name: TwitterAuthorizeNotification, handler: { _ in
            self.reset()
        })
        
        EventBox.onMainThread(self, name: EventAccountChanged, handler: { _ in
            self.reset()
        })
        
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.rawValue, sender: nil) { n in
            let status = n.object as! TwitterStatus
            for tableViewController in self.tableViewControllers {
                switch tableViewController {
                case let vc as StatusTableViewController:
                    if vc.accept(status) {
                        vc.renderData([status], mode: .TOP, handler: {})
                    }
                default:
                    break
                }
            }
        }
        
        EventBox.onMainThread(self, name: Twitter.Event.StreamingStatusChanged.rawValue) { _ in
            switch Twitter.connectionStatus {
            case .CONNECTED:
                self.streamingStatusLabel.text = "connected"
                self.streamingButton.enabled = true
                self.streamingButton.selected = true
            case .CONNECTING:
                self.streamingStatusLabel.text = "connecting..."
                self.streamingButton.enabled = true
                self.streamingButton.selected = false
            case .DISCONNECTED:
                self.streamingStatusLabel.text = "disconnected"
                if Twitter.enableStreaming {
                    self.streamingButton.enabled = false
                    self.streamingButton.selected = false
                } else {
                    self.streamingButton.enabled = true
                    self.streamingButton.selected = false
                }
            case .DISCONNECTING:
                self.streamingStatusLabel.text = "disconnecting..."
                self.streamingButton.enabled = true
                self.streamingButton.selected = false
            }
        }
        
        EventBox.onMainThread(self, name: ImageViewEvent.name) { n in
            let event = n.object as! ImageViewEvent
            if self.imageViewController == nil {
                self.imageViewController = ImageViewController()
            }
            self.imageViewController!.view.frame = self.view.frame
            self.view.addSubview(self.imageViewController!.view)
            self.imageViewController!.show(event)
        }
        
        EventBox.onMainThread(self, name: EditorEvent.name) { n in
            let event = n.object as! EditorEvent
            self.editorViewController.show()
            self.editorViewController.inReplyToStatusId = event.inReplyToStatusId
            self.editorViewController.textView.text = event.text
            if let range = event.range {
                self.editorViewController.textView.selectedRange = range
            }
        }
    }
    
    func toggleStreaming() {
        
    }
    
    func reset() {
        if let account = AccountSettingsStore.get() {
            ImageLoaderClient.displayTitleIcon(account.account().profileImageURL, imageView: self.iconImageView)
            
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
        self.settingsViewController.hide()
    }
    
    // MARK: - Actions
    
    func refresh(sender: AnyObject) {
        if (sender.state != .Began) {
            return
        }
        tableViewControllers.first?.refresh()
    }
    
    func streamingSwitch(sender: UIView) {
        StreamingAlert.show(sender)
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
