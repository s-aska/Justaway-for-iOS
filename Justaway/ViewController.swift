import UIKit
import Accounts
import Social
import EventBox
import TwitterAPI

class ViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var logoImageView: UIImageView!
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
        if AccountSettingsStore.get() != nil {
            logoImageView.hidden = true
            showView()
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.signInMenu(_:)))
        longPress.minimumPressDuration = 2.0
        signInButton.addGestureRecognizer(longPress)
    }

    func toggleView() {
        logoImageView.hidden = true
        if let _ = AccountSettingsStore.get()?.account() {
            showView()
        } else {
            timelineViewController?.view.hidden = true
            signInView.hidden = false
            signInButton.hidden = false
            signInButton.enabled = true
        }
    }

    func showView() {
        if timelineViewController == nil {
            timelineViewController = TimelineViewController()
            ViewTools.addSubviewWithEqual(containerView, view: timelineViewController!.view)

            if let settings = AccountSettingsStore.get() {
                if settings.accounts.contains({ !$0.exToken.isEmpty }) {
                    NSLog("has exToken")
                    let settings = UIUserNotificationSettings(forTypes: [.Badge, .Sound, .Alert], categories: nil)
                    UIApplication.sharedApplication().registerForRemoteNotifications()
                    UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                }
            }
        }
        timelineViewController?.view.hidden = false
        signInView.hidden = true
        signInButton.hidden = true
        signInButton.enabled = false
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: twitterAuthorizeNotification, handler: { _ in
            self.toggleView()
        })
    }

    // MARK: - Actions

    func signInMenu(sender: UILongPressGestureRecognizer) {
        if sender.state == .Began {
            AddAccountAlert.show(signInButton)
        }
    }

    @IBAction func signInButtonClick(sender: UIButton) {
        Twitter.addACAccount(false)
    }

    @IBAction func terms(sender: UIButton) {
        Safari.openURL("http://justaway.info/iOS/terms.html")
    }

    @IBAction func privacy(sender: UIButton) {
        Safari.openURL("http://justaway.info/iOS/privacy.html")
    }
}
