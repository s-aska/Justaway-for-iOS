import UIKit
import SwifteriOS
import EventBox

class TimelineViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var homeButton: UIButton!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    var tableViewControllers = [TimelineTableViewController]()
    var connectionStatus: ConnectionStatus = .DISCONNECTIED
    var streamingRequest: SwifterHTTPRequest?
    
    enum ConnectionStatus {
        case CONNECTING
        case CONNECTIED
        case DISCONNECTING
        case DISCONNECTIED
    }
    
    struct Static {
        private static let connectionQueue = NSOperationQueue()
    }
    
    override var nibName: String {
        return "TimelineViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Static.connectionQueue.maxConcurrentOperationCount = 1
        
        editorViewController = EditorViewController()
        editorViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(self.view, view: editorViewController.view)
        
        settingsViewController = SettingsViewController()
        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)
        
        var size = scrollWrapperView.frame.size
        println(size.width)
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
        
//        tableViewController = TimelineTableViewController()
//        tableViewController.view.frame = CGRectMake(0, 0, size.width, size.height)
//        let view = UIView(frame: CGRectMake(0, 0, size.width, size.height))
//        view.addSubview(tableViewController.view)
//        contentView.addSubview(view)
//        tableViewControllers.append(tableViewController)
        
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        EventBox.on(self, name: "streamingOn", sender: nil, queue: Static.connectionQueue) { n in
            if self.connectionStatus == .DISCONNECTIED {
                self.connectionStatus = .CONNECTING
                NSLog("connectionStatus: CONNECTING")
                self.toggleStreaming()
            }
        }
        
        EventBox.on(self, name: "streamingOff", sender: nil, queue: Static.connectionQueue) { n in
            if self.connectionStatus == .CONNECTIED {
                self.connectionStatus = .DISCONNECTIED
                NSLog("connectionStatus: DISCONNECTIED")
                self.streamingRequest?.stop()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            }
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        EventBox.off(self)
    }
    
    func toggleStreaming() {
        let progress = {
            (data: [String: JSONValue]?) -> Void in
            
            if self.connectionStatus != .CONNECTIED {
                self.connectionStatus = .CONNECTIED
                NSLog("connectionStatus: CONNECTIED")
            }
            
            if data == nil {
                return
            }
            
            let responce = JSON.JSONObject(data!)
            
            if let event = responce["event"].object {
                
            } else if let delete = responce["delete"].object {
            } else if let status = responce["delete"]["status"].object {
            } else if let direct_message = responce["delete"]["direct_message"].object {
            } else if let direct_message = responce["direct_message"].object {
            } else if let text = responce["text"].string {
                let status = TwitterStatus(responce)
                self.tableViewControllers.first?.renderData([status], mode: .TOP, handler: {})
            }
            
            //            println(responce)
        }
        let stallWarningHandler = {
            (code: String?, message: String?, percentFull: Int?) -> Void in
            
            println("code:\(code) message:\(message) percentFull:\(percentFull)")
        }
        let failure = {
            (error: NSError) -> Void in
            
            self.connectionStatus = .DISCONNECTIED
            NSLog("connectionStatus: DISCONNECTIED")
            
            println(error)
        }
        if let account = AccountSettingsStore.get() {
            self.streamingRequest = Twitter.getClient(account.account()).getUserStreamDelimited(nil,
                stallWarnings: nil,
                includeMessagesFromFollowedAccounts: nil,
                includeReplies: nil,
                track: nil,
                locations: nil,
                stringifyFriendIDs: nil,
                progress: progress,
                stallWarningHandler: stallWarningHandler,
                failure: failure)
        }
    }
    
    // MARK: - Actions
    
    func refresh(sender: AnyObject) {
        tableViewControllers.first?.loadData(nil)
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
