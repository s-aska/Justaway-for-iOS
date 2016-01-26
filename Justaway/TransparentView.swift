import UIKit

class TransparentView: UIView {

    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let view: UIView? = super.hitTest(point, withEvent: event)
        if view === self {
            return nil // Delegates to the parent layer
        }
        return view // Child layer ( UIButton ...etc )
    }

}
