import UIKit
import Accounts
import Social
import EventBox
import TwitterAPI

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var signInView: UIView!
    @IBOutlet weak var signInButton: UIButton!
    
    var timelineViewController: TimelineViewController?
    
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
        toggleView()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        
    }
    
    func toggleView() {
        if let _ = AccountSettingsStore.get() {
            if timelineViewController == nil {
                timelineViewController = TimelineViewController()
                ViewTools.addSubviewWithEqual(containerView, view: timelineViewController!.view)
            }
            timelineViewController?.view.hidden = false
            signInView.hidden = true
            signInButton.hidden = true
            signInButton.enabled = false
        } else {
            timelineViewController?.view.hidden = true
            signInView.hidden = false
            signInButton.hidden = false
            signInButton.enabled = true
        }
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: TwitterAuthorizeNotification, handler: { _ in
            self.toggleView()
        })
    }
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        Twitter.addOAuthAccount()
    }
    
}

