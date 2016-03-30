import UIKit

class ViewTools {

    struct Static {
        static var overlayViewControllers = [String: [UIViewController]]()
    }

    struct Constants {
        static let duration: Double = 0.2
        static let delay: NSTimeInterval = 0
    }

    // 上下左右ピッタリにviewを追加する
    // 使用例: Storyboard で top/bottom layout guide に合わせた containerView に別のVCのviewを追加する
    class func addSubviewWithEqual(containerView: UIView, view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: 0.0))
        containerView.addConstraints(constraints)
    }

    class func addSubviewWithEqual(containerView: UIView, view: UIView, top: CGFloat?, right: CGFloat?, bottom: CGFloat?, left: CGFloat?) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        var constraints = [NSLayoutConstraint]()
        if let t = top {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: t))
        }
        if let r = right {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .Right, relatedBy: .Equal, toItem: view, attribute: .Right, multiplier: 1.0, constant: r))
        }
        if let b = bottom {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: b))
        }
        if let l = left {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1.0, constant: l))
        }
        containerView.addConstraints(constraints)
    }

    class func addSubviewWithCenter(containerView: UIView, view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
        containerView.addConstraints(constraints)
    }

    class func frontViewController() -> UIViewController? {
        if var vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            while let presentedViewController = vc.presentedViewController {
                vc = presentedViewController
            }
            return vc
        }
        return nil
    }

    class func slideIn(viewController: UIViewController) {
        let key = NSStringFromClass(viewController.dynamicType)
        guard let rootViewController = frontViewController() else {
            return
        }

        EditorViewController.hide()

        viewController.view.hidden = true
        viewController.view.frame = CGRectOffset(rootViewController.view.frame, rootViewController.view.frame.width, 0)
        rootViewController.view.addSubview(viewController.view)
        viewController.view.hidden = false

        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: { () -> Void in
            viewController.view.frame = rootViewController.view.frame
            }) { (finished) -> Void in
        }
        if let viewControllers = Static.overlayViewControllers[key] {
            Static.overlayViewControllers[key] = viewControllers + [viewController]
        } else {
            Static.overlayViewControllers[key] = [viewController]
        }
    }

    class func slideOut(viewController: UIViewController) {
        let key = NSStringFromClass(viewController.dynamicType)
        UIView.animateWithDuration(Constants.duration, delay: Constants.delay, options: .CurveEaseOut, animations: {
            viewController.view.frame = CGRectOffset(viewController.view.frame, viewController.view.frame.size.width, 0)
            }, completion: { finished in
                viewController.view.hidden = true
                viewController.view.removeFromSuperview()
                Static.overlayViewControllers[key]?.removeLast()
        })
    }
}
