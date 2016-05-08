//
//  Toast.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/4/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Async

class ToastViewController: UIViewController {

    // MARK: Properties

    @IBOutlet weak var messageLabel: StatusLable!
    @IBOutlet weak var messageHeightConstraint: NSLayoutConstraint!

    var message: String?
    var completion: (() -> ())?

    override var nibName: String {
        return "ToastViewController"
    }

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    // MARK: - Configuration

    func configureView() {
        messageLabel.text = message
        messageLabel.backgroundColor = UIColor.clearColor()
        messageHeightConstraint.constant = measure(message ?? "")

        Async.background(after: 2, block: {
            Async.main {
                ViewTools.slideOutLeft(self)
            }
            self.completion?()
        })
    }

    // MARK: - Private

    private func measure(text: NSString) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSize.init(width: self.messageLabel.frame.size.width, height: 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(CGFloat(GenericSettings.get().fontSize))],
            context: nil).size.height)
    }

    // MARK: - Public

    class func show(message: String, completion: (() -> ())) {
        let instance = ToastViewController()
        instance.message = message
        instance.completion = completion
        Async.main {
            ViewTools.slideIn(instance, keepEditor: true)
        }
    }
}
