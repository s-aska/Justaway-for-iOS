import UIKit

class SettingsViewController: UIViewController {
    // MARK: Properties
    
    @IBOutlet weak var fontSizeSettingsView: UIView!
    @IBOutlet weak var themeSettingsView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewBottomConstraint: NSLayoutConstraint!
    
    var currentSettingsView: UIView!
    
    // MARK: Actions
    
    @IBAction func hide(sender: UIButton) {
        hide()
    }
    
    @IBAction func showFontSizeSettingsView(sender: UIButton) {
        showSettingsView(fontSizeSettingsView)
    }
    
    @IBAction func showThemeSettingsView(sender: UIButton) {
        showSettingsView(themeSettingsView)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerViewBottomConstraint.constant = -containerView.frame.size.height
        fontSizeSettingsView.hidden = true
        themeSettingsView.hidden = true
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
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            view.frame = CGRectMake(0,
                view.frame.origin.y,
                view.frame.size.width,
                view.frame.size.height)
        }, { finished in
        })
    }
    
    func hideSettingsView(view: UIView, completion: (Void -> Void)?) {
        currentSettingsView = nil
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
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
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, { finished in
        })
    }
    
    func hide() {
        
        func hideContainer() {
            containerViewBottomConstraint.constant = -containerView.frame.size.height
            UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
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
