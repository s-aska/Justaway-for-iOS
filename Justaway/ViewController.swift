import UIKit
import Accounts
import Social
import SwifteriOS
import EventBox

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    var timelineViewController: TimelineViewController!
    
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
        timelineViewController = TimelineViewController()
        ViewTools.addSubviewWithEqual(containerView, view: timelineViewController.view)
        toggleView()
    }
    
    func toggleView() {
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
    
    func configureEvent() {
        EventBox.onMainThread(self, name: TwitterAuthorizeNotification, handler: { _ in
            self.toggleView()
        })
    }
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        AddAccountAlert.show()
    }
    
}

