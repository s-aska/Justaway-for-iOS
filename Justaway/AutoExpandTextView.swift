import UIKit

class AutoExpandTextView: UITextView, UITextViewDelegate {
    // MARK: Properties
    
    var constraint: NSLayoutConstraint!
    var minHeight: NSNumber!
    
    // MARK: Configuration
    
    func configure(heightConstraint c: NSLayoutConstraint) {
        delegate = self
        constraint = c
        minHeight = c.constant
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        setHeight(max(textView.contentSize.height, minHeight))
    }
    
    // MARK: 
    
    func reset() {
        text = ""
        setHeight(minHeight)
    }
    
    func setHeight(height: NSNumber) {
        var f = frame
        f.size.height = height
        frame = f
        
        setContentOffset(CGPointZero, animated: false) // iOS8(GM) has bug?
        
        constraint.constant = height
    }
}
