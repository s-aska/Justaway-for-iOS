import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var editorView: UIView!
    @IBOutlet weak var editorViewButtomConstraint: NSLayoutConstraint!
    @IBOutlet weak var editorTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIButton.appearance().setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        NSLog("handleKeyboardWillShowNotification")
        let userInfo = notification.userInfo!
        
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
    }
    
    func handleKeyboardWillHideNotification(notification: NSNotification) {
        NSLog("handleKeyboardWillHideNotification")
        
    }
    
    @IBAction func signInButtonClick(sender: UIButton) {
        NSLog("signInButtonClick")
    }
    
    @IBAction func writeButtonClick(sender: UIButton) {
        // self.editorView.hidden = false
        // editorViewButtomConstraint.constant = 100
        if (self.editorView.hidden) {
            self.editorView.hidden = false;
//            self.editorView.alpha = 0;
            self.editorTextView.becomeFirstResponder()
//            [self.editorTextView becomeFirstResponder];
        }
    }
}

