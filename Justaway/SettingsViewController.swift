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
    var accountViewController: AccountViewController!
    
    override var nibName: String {
        return "SettingsViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSettingsView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    // MARK: - Configuration
    
    func configureSettingsView() {
        let menuHeight = containerView.frame.size.height
        
        containerViewBottomConstraint.constant = -menuHeight
        
        fontSizeViewController = FontSizeViewController()
        fontSizeViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(view, view: fontSizeViewController.view, top: nil, right: 0.0, bottom: menuHeight, left: 0.0)
        
        themeViewController = ThemeViewController()
        themeViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(view, view: themeViewController.view, top: nil, right: 0.0, bottom: menuHeight, left: 0.0)
        
        accountViewController = AccountViewController()
        accountViewController.view.hidden = true
        ViewTools.addSubviewWithEqual(view, view: accountViewController.view, top: 0.0, right: 0.0, bottom: menuHeight, left: 0.0)
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
    
    @IBAction func showAccountViewController(sender: UIButton) {
        showSettingsView(accountViewController.view)
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
        view.frame = CGRectMake(view.frame.size.width,
            view.frame.origin.y,
            view.frame.size.width,
            view.frame.size.height)
        view.hidden = false
        
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
            view.frame = CGRectMake(0,
                view.frame.origin.y,
                view.frame.size.width,
                view.frame.size.height)
        }) { (finished) -> Void in
            
        }
    }
    
    func hideSettingsView(view: UIView, completion: (Void -> Void)?) {
        currentSettingsView = nil
        
        // Slide out
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            view.frame = CGRectMake(-view.frame.size.width,
                view.frame.origin.y,
                view.frame.size.width,
                view.frame.size.height)
        }, { finished in
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
        }, { finished in
        })
    }
    
    func hide() {
        
        func hideContainer() {
            containerViewBottomConstraint.constant = -containerView.frame.size.height
            
            UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
                self.view.layoutIfNeeded()
            }, { finished in
            })
        }
        
        if currentSettingsView != nil {
            hideSettingsView(currentSettingsView, hideContainer)
        } else {
            hideContainer()
        }
    }
    
}
