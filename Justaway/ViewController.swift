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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
        if AccountSettingsStore.get() != nil {
            logoImageView.isHidden = true
            showView()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
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
        logoImageView.isHidden = true
        if let _ = AccountSettingsStore.get()?.account() {
            showView()
        } else {
            timelineViewController?.view.isHidden = true
            signInView.isHidden = false
            signInButton.isHidden = false
            signInButton.isEnabled = true
        }
    }

    func showView() {
        if timelineViewController == nil {
            timelineViewController = TimelineViewController()
            ViewTools.addSubviewWithEqual(containerView, view: timelineViewController!.view)

            if let settings = AccountSettingsStore.get() {
                if settings.accounts.contains(where: { !$0.exToken.isEmpty }) {
                    NSLog("has exToken")
                    let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
                    UIApplication.shared.registerForRemoteNotifications()
                    UIApplication.shared.registerUserNotificationSettings(settings)
                }
            }
        }
        timelineViewController?.view.isHidden = false
        signInView.isHidden = true
        signInButton.isHidden = true
        signInButton.isEnabled = false
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: twitterAuthorizeNotification, handler: { _ in
            self.toggleView()
        })
    }

    // MARK: - Actions

    func signInMenu(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            AddAccountAlert.show(signInButton)
        }
    }

    @IBAction func signInButtonClick(_ sender: UIButton) {
        Twitter.addACAccount(false)
    }

    @IBAction func terms(_ sender: UIButton) {
        Safari.openURL("http://justaway.info/iOS/terms.html")
    }

    @IBAction func privacy(_ sender: UIButton) {
        Safari.openURL("http://justaway.info/iOS/privacy.html")
    }
}
