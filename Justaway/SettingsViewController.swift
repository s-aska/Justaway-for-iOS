import UIKit

class SettingsViewController: UIViewController {

    // MARK: Types

    struct Constants {
        static let duration: Double = 0.2
        static let delay: TimeInterval = 0
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // configureEvent()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        let menuHeight = containerView.frame.size.height

        containerViewBottomConstraint.constant = -menuHeight

        fontSizeViewController = FontSizeViewController()
        fontSizeViewController.view.isHidden = true
        ViewTools.addSubviewWithEqual(view, view: fontSizeViewController.view, top: nil, right: 0.0, bottom: menuHeight, left: 0.0)

        themeViewController = ThemeViewController()
        themeViewController.view.isHidden = true
        ViewTools.addSubviewWithEqual(view, view: themeViewController.view, top: nil, right: 0.0, bottom: menuHeight, left: 0.0)
    }

    // MARK: - Actions

    @IBAction func hide(_ sender: UIButton) {
        hide()
    }

    @IBAction func showFontSizeSettingsView(_ sender: UIButton) {
        showSettingsView(fontSizeViewController.view)
    }

    @IBAction func showThemeSettingsView(_ sender: UIButton) {
        showSettingsView(themeViewController.view)
    }

    func showSettingsView(_ view: UIView) {
        if currentSettingsView != nil {
            if currentSettingsView === view {
                return
            }
            hideSettingsView(currentSettingsView, completion: nil)
        }
        currentSettingsView = view

        // Slide in
        view.isHidden = false
        let frame = view.frame.offsetBy(dx: -view.frame.origin.x, dy: 0)
        view.frame = frame.offsetBy(dx: frame.size.width, dy: 0)

        UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: { () -> Void in
            view.frame = frame
        }) { (finished) -> Void in

        }
    }

    func hideSettingsView(_ view: UIView, completion: ((Void) -> Void)?) {
        currentSettingsView = nil

        // Slide out
        UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: {
            view.frame = view.frame.offsetBy(dx: -view.frame.size.width, dy: 0)
        }, completion: { finished in
            view.isHidden = true
            if completion != nil {
                completion!()
            }
        })
    }

    func show() {
        containerViewBottomConstraint.constant = 0

        UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: { finished in
        })
    }

    func hide() {

        func hideContainer() {
            containerViewBottomConstraint.constant = -containerView.frame.size.height

            UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: {
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
