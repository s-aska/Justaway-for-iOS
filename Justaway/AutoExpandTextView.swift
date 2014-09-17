import UIKit

class AutoExpandTextView: UITextView, UITextViewDelegate {
    // MARK: Properties
    
    weak var constraint: NSLayoutConstraint!
    var minHeight: NSNumber!
    
    // MARK: Configuration
    
    func configure(heightConstraint c: NSLayoutConstraint) {
        delegate = self
        constraint = c
        minHeight = c.constant
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        exapnd(max(textView.contentSize.height, minHeight))
    }
    
    // MARK: Public
    
    func reset() {
        text = ""
        exapnd(minHeight)
    }
    
    func exapnd(height: NSNumber) {
        var f = frame
        f.size.height = height
        frame = f
        
        setContentOffset(CGPointZero, animated: false) // iOS8(GM) has bug?
        
        if constraint != nil {
            constraint.constant = height
        }
    }
}
