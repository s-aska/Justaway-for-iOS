import UIKit

class EditorViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var editorView: UIView!
    @IBOutlet weak var editorViewButtomConstraint: NSLayoutConstraint!
    @IBOutlet weak var editorTextView: UITextView!
    @IBOutlet weak var editorTextViewHeightConstraint: NSLayoutConstraint!
    
    var editorTextViewMinHeight: NSNumber!
    let editorTextViewMargin: NSNumber = 20
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editorTextView.delegate = self
        editorTextViewMinHeight = Int(editorTextViewHeightConstraint.constant) - editorTextViewMargin
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
        
        editorTextViewHeightConstraint.constant = height
    }
    
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as NSValue).CGRectValue()
        
        let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
        if (orientation.isLandscape) {
            editorViewButtomConstraint.constant = keyboardScreenEndFrame.size.width
        } else {
            editorViewButtomConstraint.constant = keyboardScreenEndFrame.size.height
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
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as NSNumber).doubleValue
        
        editorViewButtomConstraint.constant = 0
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.editorView.alpha = 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
                self.view.hidden = true
        })
    }
    
    func open() {
        view.hidden = false
        editorTextView.becomeFirstResponder()
    }
    
    func close() {
        editorTextView.text = ""
        editorTextViewHeightConstraint.constant = editorTextViewMinHeight + editorTextViewMargin
        
        if (editorTextView.isFirstResponder()) {
            editorTextView.resignFirstResponder()
        } else {
            view.hidden = true
        }
    }
    
    @IBAction func close(sender: UIButton) {
        close()
    }
}

