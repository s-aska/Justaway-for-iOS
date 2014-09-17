import UIKit

class BaseViewController: UIViewController {
    // MARK: Initializers
    
    /**
        Loading a view controller from XIB file does not work (iOS8 GM)
        See: https://devforums.apple.com/message/1017368#1017368
    */
    override init() {
        super.init(nibName: NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!, bundle: nil)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
