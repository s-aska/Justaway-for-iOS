import UIKit

class ViewTools {

    struct Static {
        static var overlayViewControllers = [String: [UIViewController]]()
    }

    struct Constants {
        static let duration: Double = 0.2
        static let delay: TimeInterval = 0
    }

    // 上下左右ピッタリにviewを追加する
    // 使用例: Storyboard で top/bottom layout guide に合わせた containerView に別のVCのviewを追加する
    class func addSubviewWithEqual(_ containerView: UIView, view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: 0.0))
        containerView.addConstraints(constraints)
    }

    // swiftlint:disable:next function_parameter_count
    class func addSubviewWithEqual(_ containerView: UIView, view: UIView, top: CGFloat?, right: CGFloat?, bottom: CGFloat?, left: CGFloat?) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        var constraints = [NSLayoutConstraint]()
        if let t = top {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1.0, constant: t))
        }
        if let r = right {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1.0, constant: r))
        }
        if let b = bottom {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1.0, constant: b))
        }
        if let l = left {
            constraints.append(NSLayoutConstraint(item: containerView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1.0, constant: l))
        }
        containerView.addConstraints(constraints)
    }

    class func addSubviewWithCenter(_ containerView: UIView, view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(view)
        var constraints = [NSLayoutConstraint]()
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        constraints.append(NSLayoutConstraint(item: containerView, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        containerView.addConstraints(constraints)
    }

    class func frontViewController() -> UIViewController? {
        if var vc = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = vc.presentedViewController {
                vc = presentedViewController
            }
            return vc
        }
        return nil
    }

    class func slideIn(_ viewController: UIViewController, keepEditor: Bool = false) {
        let key = NSStringFromClass(type(of: viewController))
        guard let rootViewController = frontViewController() else {
            return
        }

        if !keepEditor {
            EditorViewController.hide()
        }

        viewController.view.isHidden = true
        viewController.view.frame = rootViewController.view.frame.offsetBy(dx: rootViewController.view.frame.width, dy: 0)
        rootViewController.view.addSubview(viewController.view)
        viewController.view.isHidden = false

        UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: { () -> Void in
            viewController.view.frame = rootViewController.view.frame
            }) { (finished) -> Void in
        }
        if let viewControllers = Static.overlayViewControllers[key] {
            Static.overlayViewControllers[key] = viewControllers + [viewController]
        } else {
            Static.overlayViewControllers[key] = [viewController]
        }
    }

    class func slideOut(_ viewController: UIViewController) {
        let key = NSStringFromClass(type(of: viewController))
        UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: {
            viewController.view.frame = viewController.view.frame.offsetBy(dx: viewController.view.frame.width, dy: 0)
            }, completion: { finished in
                viewController.view.isHidden = true
                viewController.view.removeFromSuperview()
                Static.overlayViewControllers[key]?.removeLast()
        })
    }

    class func slideOutLeft(_ viewController: UIViewController) {
        let key = NSStringFromClass(type(of: viewController))
        UIView.animate(withDuration: Constants.duration, delay: Constants.delay, options: .curveEaseOut, animations: {
            viewController.view.frame = viewController.view.frame.offsetBy(dx: -viewController.view.frame.width, dy: 0)
            }, completion: { finished in
                viewController.view.isHidden = true
                viewController.view.removeFromSuperview()
                Static.overlayViewControllers[key]?.removeLast()
        })
    }
}
