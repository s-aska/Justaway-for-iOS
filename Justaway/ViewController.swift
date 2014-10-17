import UIKit
import Accounts
import Social
import SwifteriOS

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var timelineViewController: TimelineViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timelineViewController = TimelineViewController()
        ViewTools.addSubviewWithEqual(containerView, view: timelineViewController.view)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Notification.onMainThread(self, name: TwitterAuthorizeNotification, handler: { _ in self.configure() })
        
        configure()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        Notification.off(self)
    }
    
    // MARK: - Keyboard Event Notifications
    
    func configure() {
        if let accountSettings = AccountSettingsStore.get() {
            timelineViewController.view.hidden = false
            signInButton.hidden = true
            signInButton.enabled = false
        } else {
            timelineViewController.view.hidden = true
            signInButton.hidden = false
            signInButton.enabled = true
        }
    }
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        signInButton.enabled = false
        
        Twitter.addOAuthAccount()
    }
    
}

