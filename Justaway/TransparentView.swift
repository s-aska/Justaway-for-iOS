import UIKit

class TransparentView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view: UIView? = super.hitTest(point, with: event)
        if view === self {
            return nil // Delegates to the parent layer
        }
        return view // Child layer ( UIButton ...etc )
    }

}
