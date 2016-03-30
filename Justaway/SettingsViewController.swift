import UIKit

class SettingsViewController: UIViewController {

    // MARK: Types

    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }

    // MARK: Properties

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!

    var currentSettingsView: UIView!
    var fontSizeViewController: FontSizeViewController!
    var themeViewController: ThemeViewController!

    override var nibName: String {
        return "SettingsViewController"
    }

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
        // configureEvent()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        let menuHeight = containerView.frame.size.height

        containerViewBottomConstraint.constant = -menuHeight

        fontSizeViewController = FontSizeViewController()
        fontSizeViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(view, view: fontSizeViewController.view, top: nil, right: 0.0, bottom: menuHeight, left: 0.0)

        themeViewController = ThemeViewController()
        themeViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(view, view: themeViewController.view, top: nil, right: 0.0, bottom: menuHeight, left: 0.0)
    }

    // MARK: - Actions

    @IBAction func hide(sender: UIButton) {
        hide()
    }

    @IBAction func showFontSizeSettingsView(sender: UIButton) {
        showSettingsView(fontSizeViewController.view)
    }

    @IBAction func showThemeSettingsView(sender: UIButton) {
        showSettingsView(themeViewController.view)
    }

    func showSettingsView(view: UIView) {
        if currentSettingsView != nil {
            if currentSettingsView === view {
                return
            }
            hideSettingsView(currentSettingsView, completion: nil)
        }
        currentSettingsView = view

        // Slide in
        view.hidden = false
        let frame = view.frame
        view.frame = CGRectOffset(frame, frame.size.width, 0)

        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
            view.frame = frame
        }) { (finished) -> Void in

        }
    }

    func hideSettingsView(view: UIView, completion: (Void -> Void)?) {
        currentSettingsView = nil

        // Slide out
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            view.frame = CGRectOffset(view.frame, -view.frame.size.width, 0)
        }, completion: { finished in
            view.hidden = true
            if completion != nil {
                completion!()
            }
        })
    }

    func show() {
        containerViewBottomConstraint.constant = 0

        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }

    func hide() {

        func hideContainer() {
            containerViewBottomConstraint.constant = -containerView.frame.size.height

            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
            })
        }

        if currentSettingsView != nil {
            hideSettingsView(currentSettingsView, completion: hideContainer)
        } else {
            hideContainer()
        }
    }

}
