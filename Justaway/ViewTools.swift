import UIKit

class ViewTools {
    
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
}
