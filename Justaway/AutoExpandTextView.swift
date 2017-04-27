import UIKit

class AutoExpandTextView: UITextView, UITextViewDelegate {

    // MARK: Properties

    weak var constraint: NSLayoutConstraint!
    var minHeight: CGFloat!
    var callback: ((Void) -> Void)?

    // MARK: Configuration

    func configure(heightConstraint: NSLayoutConstraint) {
        delegate = self
        constraint = heightConstraint
        minHeight = heightConstraint.constant
    }

    // MARK: UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        exapnd(max(textView.contentSize.height, minHeight))
        callback?()
    }

    // MARK: Public

    func reset() {
        text = ""
        exapnd(minHeight)
        callback?()
    }

    func exapnd(_ height: CGFloat) {
        var f = frame
        f.size.height = height
        frame = f

        setContentOffset(CGPoint.zero, animated: false) // iOS8(GM) has bug?

        if constraint != nil {
            constraint.constant = height
        }
    }
}
