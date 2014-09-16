import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var fontSizeView: UIView!
    @IBOutlet weak var toolView: UIView!
    @IBOutlet weak var toolViewBottom: NSLayoutConstraint!
    
    var currentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolViewBottom.constant = -toolView.frame.size.height
        fontSizeView.hidden = true
    }
    
    func open() {
        toolViewBottom.constant = 0
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            self.view.layoutIfNeeded()
            }, { finished in
        })
    }
    
    func close() {
        
        func closeView() {
            toolViewBottom.constant = -toolView.frame.size.height
            UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
                self.view.layoutIfNeeded()
                }, { finished in
            })
        }
        
        if currentView != nil {
            currentView.slideOut(closeView)
            currentView = nil
        } else {
            closeView()
        }
    }
    
    @IBAction func close(sender: UIButton) {
        close()
    }
    
    @IBAction func openFontSize(sender: UIButton) {
        fontSizeView.slideIn()
        currentView = fontSizeView
    }
}

extension UIView {
    func slideIn() {
        self.hidden = false
        self.frame = CGRectMake(self.frame.size.width,
            self.frame.origin.y,
            self.frame.size.width,
            self.frame.size.height)
        self.hidden = false
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            self.frame = CGRectMake(0,
                self.frame.origin.y,
                self.frame.size.width,
                self.frame.size.height)
        }, { finished in
        })
    }
    
    func slideOut(completion: Void -> Void) {
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseOut, animations: {
            self.frame = CGRectMake(-self.frame.size.width,
                self.frame.origin.y,
                self.frame.size.width,
                self.frame.size.height)
        }, { finished in
            self.hidden = true
            completion()
        })
    }
}
