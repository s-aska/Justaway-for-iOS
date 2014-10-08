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
        
        if let accountSettings = AccountSettingsStore.get() {
            timelineViewController.view.hidden = false
            signInButton.hidden = true
        } else {
            timelineViewController.view.hidden = true
            signInButton.hidden = false
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        let failureHandler: ((NSError) -> Void) = {
            error in
        }
        let swifter = Swifter(consumerKey: TwitterConsumerKey, consumerSecret: TwitterConsumerSecret)
        let url = NSURL(string: "justaway://success")
        swifter.authorizeWithCallbackURL(url, success: {
            accessToken, response in
            
            if let token = accessToken {
                Twitter.refreshAccounts([
                    Account(
                        credential: SwifterCredential(accessToken: token),
                        userID: token.userID!,
                        screenName: token.screenName ?? "",
                        name: token.screenName! ?? "",
                        profileImageURL: NSURL(string: ""))
                    ], successHandler: {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.timelineViewController.view.hidden = false
                        self.signInButton.hidden = true
                    })
                })
            }
            
            }, failure: failureHandler)
    }
    
}

