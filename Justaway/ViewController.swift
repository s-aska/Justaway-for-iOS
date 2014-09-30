import UIKit
import Accounts
import Social

class ViewController: UIViewController {
    
    // MARK: Properties
    
    @IBOutlet weak var signInButton: UIButton!
    
    var editorViewController: EditorViewController!
    var settingsViewController: SettingsViewController!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editorViewController = EditorViewController()
        editorViewController.view.frame = view.frame
        editorViewController.view.hidden = true
        self.view.addSubview(editorViewController.view)
        
        settingsViewController = SettingsViewController()
        settingsViewController.view.frame = view.frame
        settingsViewController.view.hidden = false
        self.view.addSubview(settingsViewController.view)
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
    
    // MARK: - Actions
    
    @IBAction func signInButtonClick(sender: UIButton) {
        
    }
    
    @IBAction func homeButton(sender: UIButton) {
        if let accountSettings = AccountService.load() {
            let account = accountSettings.account()
            let url = NSURL(string: "https://api.twitter.com/1.1/statuses/home_timeline.json")
            let req = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: nil)
            req.account = ACAccountStore().accountWithIdentifier(account.accessToken)
            req.performRequestWithHandler({
                (data :NSData!, res :NSHTTPURLResponse!, error :NSError!) -> Void in
                NSLog("%@", NSString(data: data, encoding :NSUTF8StringEncoding))
            })
        }
    }
    
    @IBAction func showEditor(sender: UIButton) {
        editorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
    
}

