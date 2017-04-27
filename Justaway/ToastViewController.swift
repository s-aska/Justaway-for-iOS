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
        messageLabel.backgroundColor = UIColor.clear
        messageHeightConstraint.constant = measure(message as? NSString ?? "")

        Async.background(after: 2, {
            Async.main {
                ViewTools.slideOutLeft(self)
            }
            self.completion?()
        })
    }

    // MARK: - Private

    fileprivate func measure(_ text: NSString) -> CGFloat {
        return ceil(text.boundingRect(
            with: CGSize.init(width: self.messageLabel.frame.size.width, height: 0),
            options: NSStringDrawingOptions.usesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: CGFloat(GenericSettings.get().fontSize))],
            context: nil).size.height)
    }

    // MARK: - Public

    class func show(_ message: String, completion: @escaping (() -> ())) {
        let instance = ToastViewController()
        instance.message = message
        instance.completion = completion
        Async.main {
            ViewTools.slideIn(instance, keepEditor: true)
        }
    }
}
