import UIKit

class SettingsViewController: UIViewController {
    // MARK: Types
    
    struct Constants {
        static let duration = 0.2
        static let delay: NSNumber = 0
    }
    
    // MARK: Properties
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
    
    var currentSettingsView: UIView!
    var fontSizeViewController: FontSizeViewController!
    var themeViewController: ThemeViewController!
    
    // MARK: Actions
    
    @IBAction func hide(sender: UIButton) {
        hide()
    }
    
    @IBAction func showFontSizeSettingsView(sender: UIButton) {
        showSettingsView(fontSizeViewController.view)
    }
    
    @IBAction func showThemeSettingsView(sender: UIButton) {
        showSettingsView(themeViewController.view)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSettingsView()
    }
    
    // MARK: Configuration
    
    func configureSettingsView() {
        containerViewBottomConstraint.constant = -containerView.frame.size.height
        
        fontSizeViewController = FontSizeViewController(nibName: "FontSizeViewController", bundle: nil)
        fontSizeViewController.view.frame = view.frame
        fontSizeViewController.view.hidden = true
        self.view.addSubview(fontSizeViewController.view)
        
        themeViewController = ThemeViewController(nibName: "ThemeViewController", bundle: nil)
        themeViewController.view.frame = view.frame
        themeViewController.view.hidden = true
        self.view.addSubview(themeViewController.view)
    }
    
    // MARK: - Switch the setting view
    
    func showSettingsView(view: UIView) {
        if currentSettingsView != nil {
            if currentSettingsView === view {
                return
            }
            hideSettingsView(currentSettingsView, completion: nil)
        }
        currentSettingsView = view
        view.hidden = false
        view.frame = CGRectMake(view.frame.size.width,
            view.frame.origin.y,
            view.frame.size.width,
            view.frame.size.height)
        view.hidden = false
        
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            view.frame = CGRectMake(0,
                view.frame.origin.y,
                view.frame.size.width,
                view.frame.size.height)
        }, { finished in
        })
    }
    
    func hideSettingsView(view: UIView, completion: (Void -> Void)?) {
        currentSettingsView = nil
        
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
    
    // MARK: -
    
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
