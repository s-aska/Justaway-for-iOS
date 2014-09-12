import UIKit

class ViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var editorView: UIView!
    @IBOutlet weak var editorViewButtomConstraint: NSLayoutConstraint!
    @IBOutlet weak var editorTextView: UITextView!
    @IBOutlet weak var editorTextViewHeightConstraint: NSLayoutConstraint!
    
    var editorTextViewMinHeight: NSNumber!
    let editorTextViewMargin: NSNumber = 20
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.editorTextView.delegate = self
        UIButton.appearance().setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        editorTextViewMinHeight = Int(self.editorTextViewHeightConstraint.constant) - editorTextViewMargin
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
    
    func textViewDidChange(textView: UITextView) {
        let height = max(textView.contentSize.height, editorTextViewMinHeight) + editorTextViewMargin
        var frame = textView.frame
        frame.size.height = height
        textView.frame = frame
        self.editorTextViewHeightConstraint.constant = height
    }
    
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        NSLog("handleKeyboardWillShowNotification")
        
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        if (orientation.isLandscape) {
            self.editorViewButtomConstraint.constant = keyboardScreenEndFrame.size.width
        } else {
            self.editorViewButtomConstraint.constant = keyboardScreenEndFrame.size.height
        }
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            if (self.editorView.alpha == 0) {
                self.editorView.alpha = 1
            }
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func handleKeyboardWillHideNotification(notification: NSNotification) {
        NSLog("handleKeyboardWillHideNotification")
        
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        
        self.editorViewButtomConstraint.constant = 0
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.editorView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: {
            (finished: Bool) in
            self.editorView.hidden = true
        })
    }
    
    @IBAction func signInButtonClick(sender: UIButton) {
        NSLog("signInButtonClick")
    }
    
    @IBAction func closeEditorButtonClick(sender: UIButton) {
        
        if (self.editorTextView.isFirstResponder()) {
            self.editorTextView.resignFirstResponder()
        } else {
            self.editorView.hidden = true
        }
    }
    
    @IBAction func writeButtonClick(sender: UIButton) {
        
        if (self.editorView.hidden) {
            self.editorView.hidden = false
            self.editorView.alpha = 0
            self.editorTextView.becomeFirstResponder()
        }
    }
}

