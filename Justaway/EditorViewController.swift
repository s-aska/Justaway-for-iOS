import UIKit

class EditorViewController: UIViewController, UITextViewDelegate {
    // MARK: Properties
    
    @IBOutlet weak var containerView: UIView!
    
    /// Used to adjust the text view's position when the keyboard hides and shows.
    @IBOutlet weak var containerViewButtomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textView: UITextView!
    
    /// Used to adjust the text view's height when the text changes.
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    @IBAction func hide(sender: UIButton) {
        hide()
    }
    
    @IBAction func send(sender: UIButton) {
        
    }
    
    var textViewMinHeight: NSNumber!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        textViewMinHeight = textViewHeightConstraint.constant
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Used to adjust the text view's height when the keyboard hides and shows.
        // See: https://developer.apple.com/library/prerelease/ios/samplecode/UICatalog/Listings/Swift_UICatalog_TextViewController_swift.html
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
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        let height = max(textView.contentSize.height, textViewMinHeight)
        
        var frame = textView.frame
        frame.size.height = height
        textView.frame = frame
        textView.setContentOffset(CGPointZero, animated: false) // iOS8(GM) has bug...
        
        textViewHeightConstraint.constant = height
    }
    
    // MARK: Keyboard Event Notifications
    
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        if (orientation.isLandscape) {
            containerViewButtomConstraint.constant = keyboardScreenEndFrame.size.width
        } else {
            containerViewButtomConstraint.constant = keyboardScreenEndFrame.size.height
        }
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.containerView.alpha = 1
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func handleKeyboardWillHideNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        
        containerViewButtomConstraint.constant = 0
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.containerView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.view.hidden = true
        })
    }
    
    // MARK: - Editor control
    
    func show() {
        view.hidden = false
        textView.becomeFirstResponder()
    }
    
    func hide() {
        textView.text = ""
        textView.layoutIfNeeded() // Reset .contentSize.height
        textViewDidChange(textView)
        
        if (textView.isFirstResponder()) {
            textView.resignFirstResponder()
        } else {
            view.hidden = true
        }
    }
}

